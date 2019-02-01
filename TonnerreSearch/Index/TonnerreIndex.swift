//
//  TonnerreIndex.swift
//  TonnerreSearch
//
//  Created by Yaxin Cheng on 2018-04-22.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Foundation
import CoreServices

/// TonnerreIndex supports adding, searching, and removing one or several documents efficiently
public final class TonnerreIndex {
  private let indexFile: SKIndex
  /// The path to the index file
  public let path: URL
  
  private init(filePath: URL, indexFile: SKIndex) {
    self.path = filePath
    self.indexFile = indexFile
  }
  
  /**
   Create a tonerre index with given path
   
   - Parameter path: a path to a file location where the index can be created
   - throws: When the path directs to a file which exists already
   - returns: an instance pointing to the index
   */
  public static func create(path: String) throws -> TonnerreIndex {
    let path = URL(fileURLWithPath: path)
    return try self.create(path: path)
  }
  
  /**
   Create a tonerre index with given path
   
   - Parameter path: a path to a file location where the index can be created
   - throws: When the path directs to a file which exists already
   - returns: an instance pointing to the index
   */
  public static func create(path: URL) throws -> TonnerreIndex {
    guard
      let indexFileRef = SKIndexCreateWithURL(path as CFURL, nil, kSKIndexInverted, nil)
    else { throw TonnerreIndexError.fileCreateError }
    let indexFile = indexFileRef.takeRetainedValue()
    SKLoadDefaultExtractorPlugIns()
    return TonnerreIndex(filePath: path, indexFile: indexFile)
  }
  
  /**
   Load a TonnerreIndex from a given path with a mode
   
   - parameter path: a path to a file location where the index can be created
   - parameter mode: a mode if the instance is allowed to readOnly or can write to the index. By default, it is `readOnly`
   - throws: TonnerreIndexError.fileOpenError when trying to open an index with writeAndRead mode, while it is already opened by some other process
   - returns: an instance pointing to the index
   - warning: Only single instance of `writeAndRead` mode is allowed. Trying to open several `writeAndRead`
   instances will throw an exception
   */
  public static func open(path: String, mode: OpenMode = .readOnly) throws -> TonnerreIndex {
    let path = URL(fileURLWithPath: path)
    return try self.open(path: path, mode: mode)
  }
  
  /**
   Load a TonnerreIndex from a given path with a mode
   
   - parameter path: a path to a file location where the index can be created
   - parameter mode: a mode if the instance is allowed to readOnly or can write to the index. By default, it is `readOnly`
   - throws: TonnerreIndexError.fileOpenError when trying to open an index with writeAndRead mode, while it is already opened by some other process
   - returns: an instance pointing to the index
   - warning: Only single instance of `writeAndRead` mode is allowed. Trying to open several `writeAndRead`
   instances will throw an exception
   */
  public static func open(path: URL, mode: OpenMode = .readOnly) throws -> TonnerreIndex {
    guard
      let indexFileRef = SKIndexOpenWithURL(path as CFURL, nil, mode.rawValue)
    else { throw TonnerreIndexError.fileOpenError }
    let indexFile = indexFileRef.takeRetainedValue()
    if mode == .writeAndRead { SKLoadDefaultExtractorPlugIns() }
    return TonnerreIndex(filePath: path, indexFile: indexFile)
  }
  /**
   Add a single document from a given directory path
   
   - Parameter path: a path of the file needs to be added
   - Parameter contentType: a indicator for either file name or file content should be added to the index
   - Parameter additionalNote: extra information the user may want to include in the index with this document
   - Throws: `TonnerreIndexError.fileNotExist` if the file cannot be located
   - Returns: A bool values indicating the success of adding to index
   */
  public func addDocument(atPath path: String,
                          contentType: ContentType,
                          additionalNote: String = "") throws -> Bool {
    let url = URL(fileURLWithPath: path)
    return try addDocument(atPath: url,
                           contentType: contentType,
                           additionalNote: additionalNote)
  }
  /**
   Add a single document from a given directory path
   
   - Parameter atPath: a path of the file needs to be added
   - Parameter contentType: a indicator for either file name or file content should be added to the index
   - Parameter additionalNote: extra information the user may want to include in the index with this document
   - Throws: `TonnerreIndexError.fileNotExist` if the file cannot be located
   - Returns: A bool values indicating the success of adding to index
   */
  public func addDocument(atPath path: URL,
                          contentType: ContentType,
                          additionalNote: String = "") throws -> Bool {
    let fileManager = FileManager.default
    if !fileManager.fileExists(atPath: path.path) {
      throw TonnerreIndexError.fileNotExist(atPath: path.path)
    }
    var addResult: Bool = false
    autoreleasepool {
      let fileURL = path as CFURL
      guard
        let document = SKDocumentCreateWithURL(fileURL)?.takeRetainedValue()
      else { addResult = false; return }
      if contentType == .fileName {
        let fileName = path.lastPathComponent
          .trimmingCharacters(in: .whitespacesAndNewlines)
        let fileNameLatinized = fileName
          .applyingTransform(.toLatin, reverse: false)?
          .applyingTransform(.stripDiacritics, reverse: false)?
          .applyingTransform(.stripCombiningMarks, reverse: false) ?? fileName
        let indexNotes = Set([fileName, fileNameLatinized, additionalNote].filter { !$0.isEmpty })
        let textContent = indexNotes.joined(separator: " ") as CFString
        addResult = SKIndexAddDocumentWithText(indexFile, document, textContent, true)
      } else {
        addResult = SKIndexAddDocument(indexFile, document, nil, true)
      }
      
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
  public func search(query: String, limit: Int, options: SearchOptions = .default, timeLimit: Double = 1) -> [URL] {
    let searchQuery = SKSearchCreate(indexFile, query as CFString, options.rawValue).takeRetainedValue()
    var foundDocIDs = [SKDocumentID](repeating: 0, count: limit)
    var foundScores = [Float](repeating: 0, count: limit)
    var foundCount: CFIndex = 0
    _ = SKSearchFindMatches(searchQuery, limit as CFIndex, &foundDocIDs, &foundScores, timeLimit as CFTimeInterval, &foundCount)
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
}
