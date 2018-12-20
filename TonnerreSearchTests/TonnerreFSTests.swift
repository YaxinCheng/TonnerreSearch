//
//  TonnerreFDTests.swift
//  TonnerreSearchTests
//
//  Created by Yaxin Cheng on 2018-04-23.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Foundation
import XCTest
@testable import TonnerreSearch

class TonnerreFSTests: XCTestCase {
  var eventList: [TonnerreFSDetector.event] = []
  var fsDetector: TonnerreFSDetector!
  let testFolder = NSHomeDirectory() + "/testFolder"
  
  override func setUp() {
    do {
      try FileManager.default.createDirectory(atPath: testFolder, withIntermediateDirectories: true, attributes: nil)
    } catch {
      print(error)
      fatalError("Folder failed to create")
    }
    fsDetector = TonnerreFSDetector(pathes: testFolder, callback: fileEventsOccured)
    fsDetector.start()
  }
  
  override func tearDown() {
    do {
      try FileManager.default.removeItem(at: URL(fileURLWithPath: testFolder))
    } catch {
      print(error)
    }
    fsDetector.stop()
  }
  
  func fileEventsOccured(events: [TonnerreFSDetector.event]) {
    eventList = events
    let notification = Notification(name: .TonnerreFSEventArrives, object: nil, userInfo: ["events": events])
    NotificationCenter.default.post(notification)
  }
  
  func testDetection() {
    let _ = expectation(forNotification: .TonnerreFSEventArrives, object: nil, handler: nil)
    let path = testFolder + "/randomFileUsedToCreate"
    _ = FileManager.default.createFile(atPath: path, contents: "Hello World".data(using: .utf8)!, attributes: nil)
    waitForExpectations(timeout: 6, handler: nil)
    try? FileManager.default.removeItem(atPath: path)
  }
  
  func testCorrectness() {
    let path = testFolder + "/randomFileUsedToDetectCorrectness"
    _ = FileManager.default.createFile(atPath: path, contents: "Hello World".data(using: .utf8)!, attributes: nil)
    let _ = expectation(forNotification: .TonnerreFSEventArrives, object: nil) {
      guard
        let info = $0.userInfo as? [String: [TonnerreFSDetector.event]],
        let eventList = info["events"]
      else { return false }
      return eventList.map({$0.path}).contains(path)
    }
    waitForExpectations(timeout: 6, handler: nil)
    try? FileManager.default.removeItem(atPath: path)
  }
  
  func testInsideApp() {
    let path = testFolder + "/random.app/randomFileUsedToDetectCorrectness"
    let appDir = testFolder + "/random.framework/"
    try? FileManager.default.createDirectory(atPath: appDir, withIntermediateDirectories: true, attributes: nil)
    _ = FileManager.default.createFile(atPath: path, contents: "Hello World".data(using: .utf8)!, attributes: nil)
    let _ = expectation(forNotification: .TonnerreFSEventArrives, object: nil) {
      guard
        let info = $0.userInfo as? [String: [TonnerreFSDetector.event]],
        let eventList = info["events"]
        else { return false }
      return !eventList.map({$0.path}).contains(path)
    }
    waitForExpectations(timeout: 6, handler: nil)
    try? FileManager.default.removeItem(atPath: path)
    try? FileManager.default.removeItem(atPath: appDir)
  }
  
  func testDelayedNotification() {
    fsDetector.stop()
    let path = testFolder + "/randomFileTestingDelayedNotification"
    _ = FileManager.default.createFile(atPath: path, contents: "Random".data(using: .utf8), attributes: nil)
    fsDetector.start()
    let _ = expectation(forNotification: .TonnerreFSEventArrives, object: nil) {
      guard
        let info = $0.userInfo as? [String: [TonnerreFSDetector.event]],
        let eventList = info["events"]
        else { return false }
      return eventList.map({$0.path}).contains(path)
    }
    waitForExpectations(timeout: 6, handler: nil)
    try? FileManager.default.removeItem(atPath: path)
  }
}

fileprivate extension Notification.Name {
  fileprivate static let TonnerreFSEventArrives = Notification.Name("TonnerreFSEventArrives")
}
