//
//  TonnerreIndex.swift
//  TonnerreSearch
//
//  Created by Yaxin Cheng on 2018-04-22.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Foundation
import CoreServices

/**
 It supposes adding, searching, and removing one or several documents efficiently
*/
public struct TonnerreIndex {
  private let indexFile: SKIndex
  private let path: URL
  public let type: TonnerreIndexType
  private typealias documentAddFunc = (SKIndex, SKDocument, CFString?, Bool) -> Bool
  
  /**
   Initialize a tonerre index with given filePath
   
   - Parameter filePath: a path to a file location where the index can be located or created
   - Parameter indexType: the type of this index file. It defines the search of documents. Can be: nameOnly, metadata
  */
  public init(filePath: String, indexType: TonnerreIndexType) {
    let path = URL(fileURLWithPath: filePath)
    self.init(filePath: path, indexType: indexType)
  }
  
  /**
   Initialize a tonerre index with given filePath
   
   - Parameter filePath: a path to a file location where the index can be located or created
   - Parameter indexType: the type of this index file. It defines the search of documents. Can be: nameOnly, metadata
   */
  public init(filePath: URL, indexType: TonnerreIndexType) {
    self.path = filePath
    self.type = indexType
    let name = filePath.lastPathComponent as CFString
    let url = filePath as CFURL
    if let foundIndexFile = SKIndexOpenWithURL(url, name, true)?.takeRetainedValue() {
      indexFile = foundIndexFile
    } else {
      let indexType = SKIndexType(kSKIndexInverted.rawValue)
      indexFile = SKIndexCreateWithURL(url, name, indexType, nil).takeRetainedValue()
    }
    SKLoadDefaultExtractorPlugIns()
  }
  /**
   Add a single document from a given directory path
   
   - Parameter atPath: a path of the file needs to be added
   - Parameter additionalNote: extra information the user may want to include in the index with this document
   - Throws: `TonnerreIndexError.fileNotExist` if the file cannot be located
   - Returns: A bool values indicating the success of adding to index
   */
  public func addDocument(atPath: String, additionalNote: String = "") throws -> Bool {
    let path = URL(fileURLWithPath: atPath)
    return try addDocument(atPath: path, additionalNote: additionalNote)
  }
  /**
   Add a single document from a given directory path
   
   - Parameter atPath: a path of the file needs to be added
   - Parameter additionalNote: extra information the user may want to include in the index with this document
   - Throws: `TonnerreIndexError.fileNotExist` if the file cannot be located
   - Returns: A bool values indicating the success of adding to index
   */
  public func addDocument(atPath: URL, additionalNote: String = "") throws -> Bool {
    let fileManager = FileManager.default
    if !fileManager.fileExists(atPath: atPath.path) {
      throw TonnerreIndexError.fileNotExist(atPath: atPath.path)
    }
    if atPath.lastPathComponent.starts(with: ".") { return true }
    let fileName = atPath.lastPathComponent
    let fileURL = atPath as CFURL
    guard
      let document = SKDocumentCreateWithURL(fileURL)?.takeRetainedValue()
      else { return false }
    defer { SKIndexFlush(indexFile) }
    let addMethod: documentAddFunc = type == .nameOnly ? SKIndexAddDocumentWithText : SKIndexAddDocument
    let textContent: CFString? = type == .nameOnly ? (fileName + " \(additionalNote)") as CFString : nil
    return addMethod(indexFile, document, textContent, true)
  }
  /**
   Search documents with a given query
   
   - Parameter query: the query used for searching documents
   - Parameter limit: the limit for number of documents returned by the search function
   - Parameter options: search options
   - Parameter timeLimit: the number of seconds the search can run in the maximum. 1 by default
   - Returns: An array of URLs to the found documents
  */
  public func search(query: String, limit: Int, options: TonnerreSearchOptions..., timeLimit: Double = 1) -> [URL] {
    let skOptions = options.map({$0.rawValue}).reduce(0, |)
    let searchQuery = SKSearchCreate(indexFile, query as CFString, skOptions).takeRetainedValue()
    var foundDocIDs = [SKDocumentID](repeating: 0, count: limit)
    var foundScores = [Float](repeating: 0, count: limit)
    var foundCount = 0 as CFIndex
    let _ = SKSearchFindMatches(searchQuery, limit as CFIndex, &foundDocIDs, &foundScores, timeLimit as CFTimeInterval, &foundCount)
    guard foundCount > 0 else { return [] }
    var foundURLs = [Unmanaged<CFURL>?](repeating: nil, count: foundCount)
    SKIndexCopyDocumentURLsForDocumentIDs(indexFile, foundCount, &foundDocIDs, &foundURLs)
    let extractedURLs = foundURLs.map({ $0?.takeRetainedValue() as URL? })
    let keptURLs = zip(foundScores, extractedURLs).filter({ $0.1 != nil })
    let sortedByScores = keptURLs.sorted(by: { $0.0 > $1.0 })
    let finalURLs = sortedByScores.compactMap({ $0.1 })
    return finalURLs
  }
  
  /**
   Remove a document from the index and delete all related documents
   - Parameter atPath: the path of the file needs to be removed
   - Returns: The result of remove
  */
  public func removeDocument(atPath: String) -> Bool {
    let fileURL = URL(fileURLWithPath: atPath)
    return removeDocument(atPath: fileURL)
  }
  
  /**
   Remove a document from the index and delete all related documents
   - Parameter atPath: the path of the file needs to be removed
   - Returns: The result of remove
   */
  public func removeDocument(atPath: URL) -> Bool {
    guard let document = SKDocumentCreateWithURL(atPath as CFURL)?.takeRetainedValue() else { return false }
    let result = SKIndexRemoveDocument(indexFile, document)
    SKIndexCompact(indexFile)
    return result
  }
}
