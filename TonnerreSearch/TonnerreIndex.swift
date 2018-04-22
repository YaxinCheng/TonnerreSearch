//
//  TonnerreIndex.swift
//  TonnerreSearch
//
//  Created by Yaxin Cheng on 2018-04-22.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Foundation
import CoreServices

public struct TonnerreIndex {
  private let indexFile: SKIndex
  private let path: String
  
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
      throw TonnerreIndexError.fileNotExist
    }
    guard
      let dirEnumerator = fileManager.enumerator(atPath: dirPath),
      let fileNames = dirEnumerator.allObjects as? [String]
    else { return [false] }
    SKLoadDefaultExtractorPlugIns()
    defer { SKIndexFlush(indexFile) }
    let fullPaths = (dirPath as NSString).strings(byAppendingPaths: fileNames).filter({ !$0.starts(with: ".") })// Filter out hidden files
    let documents = fullPaths.map({ URL(fileURLWithPath: $0) as CFURL }).compactMap({ SKDocumentCreateWithURL($0) }).map({$0.takeRetainedValue()})
    let addMethod: (SKIndex, SKDocument, CFString?, Bool) -> Bool = useFileName ? SKIndexAddDocumentWithText : SKIndexAddDocument
    let textContent: [CFString?] = useFileName ? fileNames as [CFString] : [CFString?](repeating: nil, count: documents.count)
    return zip(documents, textContent).map({ doc, text in
      addMethod(indexFile, doc, text, true)
    })
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
      throw TonnerreIndexError.fileNotExist
    }
    let fileName = (atPath.components(separatedBy: "/").last ?? atPath) as CFString
    let fileURL = URL(fileURLWithPath: atPath) as CFURL
    guard
      let document = SKDocumentCreateWithURL(fileURL)?.takeRetainedValue()
    else { return false }
    SKLoadDefaultExtractorPlugIns()
    defer { SKIndexFlush(indexFile) }
    let addMethod: (SKIndex, SKDocument, CFString?, Bool) -> Bool = useFileName ? SKIndexAddDocumentWithText : SKIndexAddDocument
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
    let refinedQuery = options.contains(.exactSearch) ? query : query.trimmingCharacters(in: CharacterSet(charactersIn: " *")) + "*"
    let skOptions = options.filter({$0.rawValue < 5}).map({$0.rawValue}).reduce(0, |)
    let searchQuery = SKSearchCreate(indexFile, refinedQuery as CFString, skOptions).takeRetainedValue()
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
  Close the index when it is not used
  */
  public func close() {
    SKIndexClose(indexFile)
  }
}
