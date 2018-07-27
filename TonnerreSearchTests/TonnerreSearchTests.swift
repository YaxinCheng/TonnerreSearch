//
//  TonnerreSearchTests.swift
//  TonnerreSearchTests
//
//  Created by Yaxin Cheng on 2018-04-22.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import XCTest
import Foundation
@testable import TonnerreSearch

class TonnerreSearchTests: XCTestCase {
  
  let nameOnlyIndexPath = "/tmp/nameOnlyIndexFileAvoidDuplicates"
  let withContentIndexPath = "/tmp/withContentIndexFileAvoidDuplicates"
  var nameOnlyIndexFile: TonnerreIndex!
  var withContentIndexFile: TonnerreIndex!
  
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
    nameOnlyIndexFile = TonnerreIndex(filePath: nameOnlyIndexPath, indexType: .nameOnly, writable: true)
    withContentIndexFile = TonnerreIndex(filePath: withContentIndexPath, indexType: .metadata, writable: true)
    XCTAssert(FileManager.default.fileExists(atPath: nameOnlyIndexPath))
    XCTAssert(FileManager.default.fileExists(atPath: withContentIndexPath))
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    do {
      try FileManager.default.removeItem(atPath: nameOnlyIndexPath)
      try FileManager.default.removeItem(atPath: withContentIndexPath)
    } catch {
      print("IndexFile failed to delete")
    }
    super.tearDown()
  }
  
  func testAddOne() {
    // This is an example of a functional test case.
    // Use XCTXCTAssert and related functions to verify your tests produce the correct results.
    let path = "/tmp/testFileAddedAvoidDuplicates"
    let fileContent = "testFileContentAvoidDuplicates".data(using: .utf8)!
    guard FileManager.default.createFile(atPath: path, contents: fileContent, attributes: nil) else {
      assert(false, "File create failure")
    }
    do {
      let nameOnlyResult = try nameOnlyIndexFile.addDocument(atPath: path)
      let withContentResult = try withContentIndexFile.addDocument(atPath: path)
      XCTAssert(nameOnlyResult, "name only add result")
      XCTAssert(withContentResult, "with content add result")
    } catch TonnerreIndexError.fileNotExist {
      assert(false, "Cannot locate file")
    } catch {
      assert(false, "Other error happened")
    }
    defer {
      try? FileManager.default.removeItem(atPath: path)
    }
  }
  
  func testSearch() {
    let path = "/tmp/testFileWithCertainContentAvoidDuplicates.txt"
    let fileContent = """
    To be, or not to be, that is the question:
    Whether 'tis nobler in the mind to suffer
    The slings and arrows of outrageous fortune,
    Or to take arms against a sea of troubles
    And by opposing end them. To die—to sleep,
    No more; and by a sleep to say we end
    The heart-ache and the thousand natural shocks
    That flesh is heir to: 'tis a consummation
    Devoutly to be wish'd. To die, to sleep;
    """.data(using: .utf8)!
    guard FileManager.default.createFile(atPath: path, contents: fileContent, attributes: nil) else {
      assert(false, "File create failure")
    }
    do {
      let nameOnlyResult = try nameOnlyIndexFile.addDocument(atPath: path)
      let withContentResult = try withContentIndexFile.addDocument(atPath: path)
      XCTAssert(nameOnlyResult, "name only add result")
      XCTAssert(withContentResult, "with content add result")
    } catch TonnerreIndexError.fileNotExist {
      assert(false, "Cannot locate file")
    } catch {
      assert(false, "Other error happened")
    }
    defer {
      try? FileManager.default.removeItem(atPath: path)
    }
    let shouldBeZero = nameOnlyIndexFile.search(query: "question", limit: 2, options: .default)
    XCTAssert(shouldBeZero.count == 0, "Name only search should return 0 result. Actual: \(shouldBeZero)")
    let anotherZero = withContentIndexFile.search(query: "duplicate", limit: 2, options: .default)
    XCTAssert(anotherZero.count == 0, "Content search should return 0 result. Actual: \(anotherZero)")
    let anotherNonZero = withContentIndexFile.search(query: "nobler", limit: 2, options: .default)
    XCTAssert(anotherNonZero.count != 0, "Content search should find at least one result. Actual: \(anotherNonZero)")
    let shouldNotBeZero = nameOnlyIndexFile.search(query: "testFile*", limit: 2, options: .default)
    XCTAssert(shouldNotBeZero.count != 0, "Name only search should find at least one result. Actual: \(shouldNotBeZero)")
  }
  
  func testRemove() {
    let path = "/tmp/testFileAddedAvoidDuplicates"
    let fileContent = "testFileContentAvoidDuplicates".data(using: .utf8)!
    guard FileManager.default.createFile(atPath: path, contents: fileContent, attributes: nil) else {
      assert(false, "File create failure")
    }
    do {
      let nameOnlyResult = try nameOnlyIndexFile.addDocument(atPath: path)
      XCTAssert(nameOnlyResult, "name only add result")
    } catch TonnerreIndexError.fileNotExist {
      assert(false, "Cannot locate file")
    } catch {
      assert(false, "Other error happened")
    }
    try? FileManager.default.removeItem(atPath: path)
    XCTAssert(nameOnlyIndexFile.removeDocument(atPath: path))
  }
  
  func testPerformance() {
    var paths = [FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!]
    self.measure {
      let metaIndex = TonnerreIndex(filePath: "/tmp/metaIndex", indexType: .metadata, writable: true)!
      while !paths.isEmpty {
        let processing = paths.removeFirst()
        if processing.hasDirectoryPath {
          let content = (try? FileManager.default.contentsOfDirectory(atPath: processing.path)) ?? []
          paths += content.map { processing.appendingPathComponent($0) }
        } else {
          _ = try? metaIndex.addDocument(atPath: processing)
        }
      }
    }
    try? FileManager.default.removeItem(atPath: "/tmp/metaIndex")
  }
  
  func testSearchNonLatin() {
    let path = "/tmp/Chinese中文文件.txt"
    let fileContent = "random words not necessary".data(using: .utf8)!
    guard FileManager.default.createFile(atPath: path, contents: fileContent, attributes: nil) else {
      assert(false, "File create failure")
    }
    do {
      let nameOnlyResult = try nameOnlyIndexFile.addDocument(atPath: path)
      XCTAssert(nameOnlyResult, "name only add result")
    } catch TonnerreIndexError.fileNotExist {
      assert(false, "Cannot locate file")
    } catch {
      assert(false, "Other error happened")
    }
    defer {
      try? FileManager.default.removeItem(atPath: path)
    }
    let shouldFindOne = nameOnlyIndexFile.search(query: "zhong wen", limit: 2, options: .default)
    print(shouldFindOne)
    XCTAssert(shouldFindOne.count == 1, "Found one")
  }
}
