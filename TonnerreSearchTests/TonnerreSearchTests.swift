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
    nameOnlyIndexFile = try! TonnerreIndex.create(path: nameOnlyIndexPath)
    withContentIndexFile = try! TonnerreIndex.create(path: withContentIndexPath)
    XCTAssert(FileManager.default.fileExists(atPath: nameOnlyIndexPath))
    XCTAssert(FileManager.default.fileExists(atPath: withContentIndexPath))
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    do {
      nameOnlyIndexFile = nil
      try FileManager.default.removeItem(atPath: nameOnlyIndexPath)
      withContentIndexFile = nil
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
      let nameOnlyResult = try nameOnlyIndexFile.addDocument(atPath: path, contentType: .fileName)
      let withContentResult = try withContentIndexFile.addDocument(atPath: path, contentType: .fileContent)
      XCTAssert(nameOnlyResult, "name only add result")
      XCTAssert(withContentResult, "with content add result")
    } catch TonnerreIndexError.fileNotExist {
      XCTFail("Cannot locate the file")
    } catch {
      XCTFail("Other error happened")
    }
    defer {
      try? FileManager.default.removeItem(atPath: path)
    }
  }
  
  private func createFile(name: String) {
    let path = "/tmp/\(name)"
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
      removeFile(name: name)
      XCTFail("File create failure")
      return
    }
  }
  
  private func removeFile(name: String) {
    try? FileManager.default.removeItem(atPath: "/tmp/\(name)")
  }
  
  func testSearchWithName() {
    let fileName = "testFileWithCertainContentAvoidDuplicates.txt"
    createFile(name: fileName)
    defer { removeFile(name: fileName) }
    do {
      let nameOnlyResult = try nameOnlyIndexFile.addDocument(atPath: "/tmp/\(fileName)", contentType: .fileName)
      XCTAssertTrue(nameOnlyResult)
      let shouldBeZero = nameOnlyIndexFile.search(query: "question", limit: 2)
      XCTAssertEqual(shouldBeZero.count, 0)
      let shouldNotBeZero = nameOnlyIndexFile.search(query: "testFile*", limit: 2)
      XCTAssertNotEqual(shouldNotBeZero.count, 0)
    } catch {
      XCTFail(error.localizedDescription)
    }
  }
  
  func testSearchWithContent() {
    let fileName = "testFileWithCertainContentAvoidDuplicates.txt"
    createFile(name: fileName)
    defer { removeFile(name: fileName) }
    do {
      let nameOnlyResult = try withContentIndexFile.addDocument(atPath: "/tmp/\(fileName)", contentType: .fileContent)
      XCTAssertTrue(nameOnlyResult)
      let shouldBeZero = withContentIndexFile.search(query: "duplicate", limit: 2)
      XCTAssertEqual(shouldBeZero.count, 0)
      let shouldNotBeZero = withContentIndexFile.search(query: "nobler", limit: 2)
      XCTAssertNotEqual(shouldNotBeZero.count, 0)
    } catch {
      XCTFail(error.localizedDescription)
    }
  }
  
  func testRemove() {
    let path = "/tmp/testFileAddedAvoidDuplicates"
    let fileContent = "testFileContentAvoidDuplicates".data(using: .utf8)!
    guard FileManager.default.createFile(atPath: path, contents: fileContent, attributes: nil) else {
      assert(false, "File create failure")
    }
    do {
      let nameOnlyResult = try nameOnlyIndexFile.addDocument(atPath: path, contentType: .fileName)
      XCTAssert(nameOnlyResult, "name only add result")
    } catch TonnerreIndexError.fileNotExist {
      XCTFail("Cannot locate file")
    } catch {
      XCTFail("Other error happened")
    }
    try? FileManager.default.removeItem(atPath: path)
    XCTAssert(nameOnlyIndexFile.removeDocument(atPath: path))
  }
  
//  func testPerformance() {
//    var paths = [FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!]
//    self.measure {
//      let metaIndex = TonnerreIndex(filePath: "/tmp/metaIndex", indexType: .metadata, writable: true)!
//      while !paths.isEmpty {
//        let processing = paths.removeFirst()
//        if processing.hasDirectoryPath {
//          let content = (try? FileManager.default.contentsOfDirectory(atPath: processing.path)) ?? []
//          paths += content.map { processing.appendingPathComponent($0) }
//        } else {
//          _ = try? metaIndex.addDocument(atPath: processing)
//        }
//      }
//    }
//    try? FileManager.default.removeItem(atPath: "/tmp/metaIndex")
//  }
  
  func testSearchNonLatin() {
    let path = "/tmp/Chinese中文文件.txt"
    let fileContent = "random words not necessary".data(using: .utf8)!
    guard FileManager.default.createFile(atPath: path, contents: fileContent, attributes: nil) else {
      assert(false, "File create failure")
    }
    do {
      let nameOnlyResult = try nameOnlyIndexFile.addDocument(atPath: path, contentType: .fileName)
      XCTAssert(nameOnlyResult, "name only add result")
    } catch TonnerreIndexError.fileNotExist {
      XCTFail("Cannot locate file")
    } catch {
      XCTFail("Other error happened")
    }
    defer {
      try? FileManager.default.removeItem(atPath: path)
    }
    let shouldFindOne = nameOnlyIndexFile.search(query: "zhong wen", limit: 2, options: .default)
    print(shouldFindOne)
    XCTAssert(shouldFindOne.count == 1, "Found one")
  }
  
  func testCloseOpenedIndex() {
    nameOnlyIndexFile = nil
    do {
      _ = try TonnerreIndex.open(path: nameOnlyIndexPath)
    } catch {
      XCTFail(error.localizedDescription)
    }
  }
  
  func testSearchByExtension() {
    let fileName = "testFileWithCertainContentAvoidDuplicates.txt"
    createFile(name: fileName)
    let fileNameWithTxt = "testWithtxtFileName"
    createFile(name: fileNameWithTxt)
    defer {
      removeFile(name: fileName)
      removeFile(name: fileNameWithTxt)
    }
    do {
      let nameOnlyResult = try nameOnlyIndexFile.addDocument(atPath: "/tmp/\(fileName)", contentType: .fileName)
      XCTAssertTrue(nameOnlyResult)
      let addFileWithTxt = try nameOnlyIndexFile.addDocument(atPath: "/tmp/\(fileNameWithTxt)", contentType: .fileName)
      XCTAssertTrue(addFileWithTxt)
      let shouldNotBeZero = nameOnlyIndexFile.search(query: "*.txt", limit: 2)
      XCTAssertEqual(shouldNotBeZero.count, 1)
    } catch {
      XCTFail(error.localizedDescription)
    }
  }
}
