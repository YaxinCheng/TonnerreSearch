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
  
  override func setUp() {
    let fsDetector = TonnerreFSDetector(pathes: "/tmp", callback: fileEventsOccured)
    fsDetector.start()
  }
  
  func fileEventsOccured(events: [TonnerreFSDetector.event]) {
    eventList = events
    let notification = Notification(name: .TonnerreFSEventArrives, object: nil, userInfo: ["events": events])
    NotificationCenter.default.post(notification)
  }
  
  func testDetection() {
    let _ = expectation(forNotification: .TonnerreFSEventArrives, object: nil, handler: nil)
    let path = "/tmp/randomFileUsedToCreate"
    _ = FileManager.default.createFile(atPath: path, contents: "Hello World".data(using: .utf8)!, attributes: nil)
    waitForExpectations(timeout: 6, handler: nil)
    try? FileManager.default.removeItem(atPath: path)
  }
  
  func testCorrectness() {
    let path = "/private/tmp/randomFileUsedToDetectCorrectness"
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
}

fileprivate extension Notification.Name {
  fileprivate static let TonnerreFSEventArrives = Notification.Name("TonnerreFSEventArrives")
}
