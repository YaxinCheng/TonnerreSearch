//
//  TonnerreIndex.swift
//  TonnerreSearch
//
//  Created by Yaxin Cheng on 2018-04-22.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Foundation
import CoreServices

///TonnerreIndex supports adding, searching, and removing one or several documents efficiently
public struct TonnerreIndex {
  private let indexFile: SKIndex
  public let type: TonnerreIndexType
  private typealias documentAddFunc = (SKIndex, SKDocument, CFString?, Bool) -> Bool
  
  /**
   Initialize a tonerre index with given filePath
   
   - Parameter filePath: a path to a file location where the index can be located or created
   - Parameter indexType: the type of this index file. It defines the search of documents. Can be: nameOnly, metadata
  */
  public init?(filePath: String, indexType: TonnerreIndexType, writable: Bool = false) {
    let path = URL(fileURLWithPath: filePath)
    self.init(filePath: path, indexType: indexType, writable: writable)
  }
  
  /**
   Initialize a tonerre index with given filePath
   
   - Parameter filePath: a path to a file location where the index can be located or created
   - Parameter indexType: the type of this index file. It defines the search of documents. Can be: nameOnly, metadata
   */
  public init?(filePath: URL, indexType: TonnerreIndexType, writable: Bool = false) {
    self.type = indexType
    let name = filePath.lastPathComponent as CFString
    let url = filePath as CFURL
    if let foundIndexFile = SKIndexOpenWithURL(url, name, writable)?.takeRetainedValue() {
      indexFile = foundIndexFile
    } else if writable,
      let indexFileRef = SKIndexCreateWithURL(url, name, kSKIndexInverted, nil) {
      indexFile = indexFileRef.takeRetainedValue()
    } else { return nil }
    if type == .metadata && writable { SKLoadDefaultExtractorPlugIns() }
  }
  /**
   Add a single document from a given directory path
   
   - Parameter atPath: a path of the file needs to be added
   - Parameter additionalNote: extra information the user may want to include in the index with this document
   - Throws: `TonnerreIndexError.fileNotExist` if the file cannot be located
   - Returns: A bool values indicating the success of adding to index
   */
  public func addDocument(atPath path: String, additionalNote: String = "") throws -> Bool {
    let url = URL(fileURLWithPath: path)
    return try addDocument(atPath: url, additionalNote: additionalNote)
  }
  /**
   Add a single document from a given directory path
   
   - Parameter atPath: a path of the file needs to be added
   - Parameter additionalNote: extra information the user may want to include in the index with this document
   - Throws: `TonnerreIndexError.fileNotExist` if the file cannot be located
   - Returns: A bool values indicating the success of adding to index
   */
  public func addDocument(atPath path: URL, additionalNote: String = "") throws -> Bool {
    let fileManager = FileManager.default
    if !fileManager.fileExists(atPath: path.path) {
      throw TonnerreIndexError.fileNotExist(atPath: path.path)
    }
    var addResult: Bool = false
    autoreleasepool {
      let fileName = path.deletingPathExtension().lastPathComponent
      let fileNameLatinized = fileName.applyingTransform(.toLatin, reverse: false)?.applyingTransform(.stripDiacritics, reverse: false)?.applyingTransform(.stripCombiningMarks, reverse: false) ?? fileName
      let fileURL = path as CFURL
      guard
        let document = SKDocumentCreateWithURL(fileURL)?.takeRetainedValue()
      else { addResult = false; return }
      let indexNotes = Set([fileName, fileNameLatinized, additionalNote])
      let addMethod: documentAddFunc = type == .nameOnly ? SKIndexAddDocumentWithText : SKIndexAddDocument
      let textContent: CFString? = type == .nameOnly ? indexNotes.joined(separator: " ") as CFString : nil
      addResult = addMethod(indexFile, document, textContent, false)
      SKIndexFlush(indexFile)
    }
    return addResult
  }
  /**
   Search documents with a given query
   
   - Parameter query: the query used for searching documents
   - Parameter limit: the limit for number of documents returned by the search function
   - Parameter options: search options
   - Parameter timeLimit: the number of seconds the search can run in the maximum. 1 by default
   - Returns: An array of URLs to the found documents
  */
  public func search(query: String, limit: Int, options: TonnerreSearchOptions, timeLimit: Double = 1) -> [URL] {
    let searchQuery = SKSearchCreate(indexFile, query as CFString, options.rawValue).takeRetainedValue()
    var foundDocIDs = [SKDocumentID](repeating: 0, count: limit)
    var foundScores = [Float](repeating: 0, count: limit)
    var foundCount: CFIndex = 0
    let _ = SKSearchFindMatches(searchQuery, limit as CFIndex, &foundDocIDs, &foundScores, timeLimit as CFTimeInterval, &foundCount)
    guard foundCount > 0 else { return [] }
    var foundURLs = [Unmanaged<CFURL>?](repeating: nil, count: foundCount)
    SKIndexCopyDocumentURLsForDocumentIDs(indexFile, foundCount, &foundDocIDs, &foundURLs)
    let extractedURLs = foundURLs.map { $0?.takeRetainedValue() as URL? }
    let keptURLs = zip(foundScores, extractedURLs).filter { $0.1 != nil }
    let sortedByScores = keptURLs.sorted { $0.0 > $1.0 }
    let finalURLs = sortedByScores.compactMap { $0.1 }
    return finalURLs
  }
  
  /**
   Remove a document from the index and delete all related documents
   - Parameter atPath: the path of the file needs to be removed
   - Returns: The result of remove
  */
  public func removeDocument(atPath path: String) -> Bool {
    let fileURL = URL(fileURLWithPath: path)
    return removeDocument(atPath: fileURL)
  }
  
  /**
   Remove a document from the index and delete all related documents
   - Parameter atPath: the path of the file needs to be removed
   - Returns: The result of remove
   */
  public func removeDocument(atPath path: URL) -> Bool {
    guard let document = SKDocumentCreateWithURL(path as CFURL)?.takeRetainedValue() else { return false }
    let result = SKIndexRemoveDocument(indexFile, document)
    SKIndexCompact(indexFile)
    return result
  }
  
  /// Close the index file
  public func close() {
    SKIndexClose(indexFile)
  }
}
