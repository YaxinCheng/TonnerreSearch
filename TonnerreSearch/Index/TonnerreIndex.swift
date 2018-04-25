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
  private let path: String
  private typealias documentAddFunc = (SKIndex, SKDocument, CFString?, Bool) -> Bool
  
  /**
   Initialize a tonerre index with given filePath
   
   - Parameter filePath: a path to a file location where the index can be located or created
  */
  public init(filePath: String) {
    self.path = filePath
    let name = (filePath.components(separatedBy: "/").last ?? filePath) as CFString
    let url = URL(fileURLWithPath: filePath) as CFURL
    if let foundIndexFile = SKIndexOpenWithURL(url, name, true)?.takeRetainedValue() {
      indexFile = foundIndexFile
    } else {
      let indexType = SKIndexType(kSKIndexInverted.rawValue)
      indexFile = SKIndexCreateWithURL(url, name, indexType, nil).takeRetainedValue()
    }
  }
  /**
   Add documents recursively from a given directory path
   
   - Parameter dirPath: a path contains all files needs to be added
   - Parameter useFileName: use file name instead of content of the file. Usually used for images. false by default
   - Throws: `TonnerreIndexError.fileNotExist` if the directory cannot be located
   - Returns: An array of bool values indicating the success of adding to index
  */
  public func addDocuments(dirPath: String, useFileName: Bool = false) throws -> [Bool] {
    let fileManager = FileManager.default
    if !fileManager.fileExists(atPath: dirPath) {
      throw TonnerreIndexError.fileNotExist(atPath: dirPath)
    }
    let fileNames: [String]
    do {
      fileNames = try fileManager.contentsOfDirectory(atPath: dirPath)
        .filter({ !$0.starts(with: "." )})
      if fileNames.isEmpty { return [] }
    } catch {
      throw TonnerreIndexError.indexingError(atPath: dirPath)
    }
    SKLoadDefaultExtractorPlugIns()
    defer { SKIndexFlush(indexFile) }
    let fullPaths = (dirPath as NSString).strings(byAppendingPaths: fileNames)
      .map({ URL(fileURLWithPath: $0)}).filter({!$0.isSymlink})
    let files = fullPaths.filter({ !$0.isDirectory })
    let directories = fullPaths.filter({ $0.isDirectory })
    return try files.compactMap({ try addDocument(atPath: $0, useFileName: useFileName) })
      + (try directories.compactMap({ try addDocuments(dirPath: $0, useFileName: useFileName)}).reduce([], +))
  }
  
  /**
   Add documents recursively from a given directory path
   
   - Parameter dirPath: a path contains all files needs to be added
   - Parameter useFileName: use file name instead of content of the file. Usually used for images. false by default
   - Throws: `TonnerreIndexError.fileNotExist` if the directory cannot be located
   - Returns: An array of bool values indicating the success of adding to index
   */
  public func addDocuments(dirPath: URL, useFileName: Bool = false) throws -> [Bool] {
    let fileManager = FileManager.default
    if !fileManager.fileExists(atPath: dirPath.path) {
      throw TonnerreIndexError.fileNotExist(atPath: dirPath.path)
    }
    let fileNames: [String]
    do {
      fileNames = try fileManager.contentsOfDirectory(atPath: dirPath.path)
        .filter({ !$0.starts(with: "." ) })
      if fileNames.isEmpty { return [] }
    } catch {
      throw TonnerreIndexError.indexingError(atPath: dirPath.path)
    }
    SKLoadDefaultExtractorPlugIns()
    defer { SKIndexFlush(indexFile) }
    let fullPaths = fileNames.map(dirPath.appendingPathComponent).filter({ !$0.isSymlink })
    let files = fullPaths.filter({ !$0.isDirectory })
    let directories = fullPaths.filter({ $0.isDirectory })
      return try files.compactMap({ try addDocument(atPath: $0, useFileName: useFileName) })
        + (try directories.compactMap({ try addDocuments(dirPath: $0, useFileName: useFileName)}).reduce([], +))
  }
  /**
   Add a single document from a given directory path
   
   - Parameter atPath: a path of the file needs to be added
   - Parameter useFileName: use file name instead of content of the file. Usually used for images. false by default
   - Throws: `TonnerreIndexError.fileNotExist` if the file cannot be located
   - Returns: A bool values indicating the success of adding to index
   */
  public func addDocument(atPath: String, useFileName: Bool = false) throws -> Bool {
    let fileManager = FileManager.default
    if !fileManager.fileExists(atPath: atPath) {
      throw TonnerreIndexError.fileNotExist(atPath: atPath)
    }
    let fileURL = URL(fileURLWithPath: atPath)
    if fileURL.lastPathComponent.starts(with: ".") { return true }
    let fileName = fileURL.lastPathComponent as CFString
    guard
      let document = SKDocumentCreateWithURL(fileURL as CFURL)?.takeRetainedValue()
    else { return false }
    SKLoadDefaultExtractorPlugIns()
    defer { SKIndexFlush(indexFile) }
    let addMethod: documentAddFunc = useFileName ? SKIndexAddDocumentWithText : SKIndexAddDocument
    let textContent: CFString? = useFileName ? fileName : nil
    return addMethod(indexFile, document, textContent, true)
  }
  /**
   Add a single document from a given directory path
   
   - Parameter atPath: a path of the file needs to be added
   - Parameter useFileName: use file name instead of content of the file. Usually used for images. false by default
   - Throws: `TonnerreIndexError.fileNotExist` if the file cannot be located
   - Returns: A bool values indicating the success of adding to index
   */
  public func addDocument(atPath: URL, useFileName: Bool = false) throws -> Bool {
    let fileManager = FileManager.default
    if !fileManager.fileExists(atPath: atPath.path) {
      throw TonnerreIndexError.fileNotExist(atPath: atPath.path)
    }
    if atPath.lastPathComponent.starts(with: ".") { return true }
    let fileName = atPath.lastPathComponent as CFString
    let fileURL = atPath as CFURL
    guard
      let document = SKDocumentCreateWithURL(fileURL)?.takeRetainedValue()
      else { return false }
    SKLoadDefaultExtractorPlugIns()
    defer { SKIndexFlush(indexFile) }
    let addMethod: documentAddFunc = useFileName ? SKIndexAddDocumentWithText : SKIndexAddDocument
    let textContent: CFString? = useFileName ? fileName : nil
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
    return foundURLs.compactMap { $0?.takeRetainedValue() as URL? }
  }
  
  /**
   Remove a document from the index and delete all related documents
   - Parameter atPath: the path of the file needs to be removed
   - Returns: The result of remove
  */
  public func removeDocument(atPath: String) -> Bool {
    let fileURL = URL(fileURLWithPath: atPath) as CFURL
    guard let document = SKDocumentCreateWithURL(fileURL)?.takeRetainedValue() else { return false }
    let result = SKIndexRemoveDocument(indexFile, document)
    SKIndexCompact(indexFile)
    return result
  }
  
  /**
  Close the index when it is not used
  */
  public func close() {
    SKIndexClose(indexFile)
  }
}

fileprivate extension URL {
  /**
   Check if an URL is a symlink
  */
  var isSymlink: Bool {
    let values = try? self.resourceValues(forKeys: [.isSymbolicLinkKey, .isAliasFileKey])
    guard let alias = values?.isAliasFile, let symlink = values?.isSymbolicLink else { return false }
    return alias || symlink
  }
  
  /**
   Check if an URL is a directory
   */
  var isDirectory: Bool {
    return (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
  }
}
