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
    nameOnlyIndexFile = TonnerreIndex(filePath: nameOnlyIndexPath)
    withContentIndexFile = TonnerreIndex(filePath: withContentIndexPath)
    assert(FileManager.default.fileExists(atPath: nameOnlyIndexPath))
    assert(FileManager.default.fileExists(atPath: withContentIndexPath))
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    nameOnlyIndexFile.close()
    withContentIndexFile.close()
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
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    let path = "/tmp/testFileAddedAvoidDuplicates"
    let fileContent = "testFileContentAvoidDuplicates".data(using: .utf8)!
    guard FileManager.default.createFile(atPath: path, contents: fileContent, attributes: nil) else {
      assert(false, "File create failure")
    }
    do {
      let result = try nameOnlyIndexFile.addDocument(atPath: path)
      assert(result)
    } catch TonnerreIndexError.fileNotExist {
      assert(false, "Cannot locate file")
    } catch {
      assert(false, "Other error happened")
    }
    defer {
      try? FileManager.default.removeItem(atPath: path)
    }
  }
  
  func testPerformanceExample() {
    // This is an example of a performance test case.
    self.measure {
      // Put the code you want to measure the time of here.
    }
  }
  
}
