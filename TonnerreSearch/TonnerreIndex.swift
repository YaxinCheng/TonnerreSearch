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
   - Parameter useFileName: use file name instead of content of the file. Usually used for images
   - Throws: `TonnerreIndexError.fileNotExist` if the directory cannot be located
   - Returns: An array of bool values indicating the success of adding to index
  */
  public func addDocuments(dirPath: String, useFileName: Bool = false) throws -> [Bool] {
    let fileManager = FileManager.default
    if !fileManager.fileExists(atPath: dirPath) {
      throw TonnerreIndexError.fileNotExist
    }
    SKLoadDefaultExtractorPlugIns()
    guard
      let dirEnumerator = fileManager.enumerator(atPath: dirPath),
      let fileNames = dirEnumerator.allObjects as? [String]
    else { return [false] }
    let fullPaths = (dirPath as NSString).strings(byAppendingPaths: fileNames)
    let documents = fullPaths.map({ URL(fileURLWithPath: $0) as CFURL }).compactMap({ SKDocumentCreateWithURL($0) }).map({$0.takeRetainedValue()})
    let addMethod: (SKIndex, SKDocument, CFString!, Bool) -> Bool = useFileName ? SKIndexAddDocumentWithText : SKIndexAddDocument
    let textContent: [CFString?] = useFileName ? fileNames as [CFString] : [CFString?](repeating: nil, count: documents.count)
    return zip(documents, textContent).map({ doc, text in
      addMethod(indexFile, doc, text, true)
    })
  }
  /**
   Add a single document from a given directory path
   
   - Parameter atPath: a path of the file needs to be added
   - Parameter useFileName: use file name instead of content of the file. Usually used for images
   - Throws: `TonnerreIndexError.fileNotExist` if the file cannot be located
   - Returns: A bool values indicating the success of adding to index
   */
  public func addDocument(atPath: String, useFileName: Bool = false) throws -> Bool {
    let fileManager = FileManager.default
    if !fileManager.fileExists(atPath: atPath) {
      throw TonnerreIndexError.fileNotExist
    }
    SKLoadDefaultExtractorPlugIns()
    let fileName = (atPath.components(separatedBy: "/").last ?? atPath) as CFString
    let fileURL = URL(fileURLWithPath: atPath) as CFURL
    guard
      let document = SKDocumentCreateWithURL(fileURL)?.takeRetainedValue()
    else { return false }
    let addMethod: (SKIndex, SKDocument, CFString!, Bool) -> Bool = useFileName ? SKIndexAddDocumentWithText : SKIndexAddDocument
    let textContent: CFString? = useFileName ? fileName : nil
    return addMethod(indexFile, document, textContent, true)
  }
  
  /**
  Close the index when it is not used
  */
  public func close() {
    SKIndexClose(indexFile)
  }
}
