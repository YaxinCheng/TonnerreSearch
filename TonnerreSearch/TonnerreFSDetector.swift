//
//  TonnerreFSDetector.swift
//  TonnerreSearch
//
//  Created by Yaxin Cheng on 2018-04-23.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Foundation
import CoreServices

class TonnerreFSDetector {
  private let monitoringPaths: CFArray
  private var stream: FSEventStreamRef! = nil
  private let streamCallBack: FSEventStreamCallback
  private let callback: ([event])->Void
  public typealias event = (path: String, flags: [TonnerreFSEvent])
  weak var delegate: TonnerreFSDetectorDelegate?
  
  public init(paths: [String], callback: @escaping ([event])->Void) {
    self.callback = callback
    monitoringPaths = paths as CFArray
    streamCallBack = { (stream, clientCallBackInfo, numEvents, eventPaths, eventFlags, eventIds) in
      let cString = eventPaths.assumingMemoryBound(to: UnsafePointer<CChar>.self)
      let filePaths = (0 ..< numEvents).map { String(cString: cString[$0]) }
      let fileFlags = (0 ..< numEvents).map { TonnerreFSEvent.segregate(flags: eventFlags[$0]) }
      let filteredEvents = zip(filePaths, fileFlags).filter {
        !($0.0.components(separatedBy: "/").last ?? "").starts(with: ".")
      }
      if let info = clientCallBackInfo {
        let mySelf = Unmanaged<TonnerreFSDetector>.fromOpaque(info).takeUnretainedValue()
        mySelf.callback(filteredEvents)
      }
    }
  }
  
  private func constructStream() {
    let mySelf = Unmanaged.passRetained(self).toOpaque()
    var context = FSEventStreamContext(version: 0, info: mySelf, retain: nil, release: nil, copyDescription: nil)
    stream = FSEventStreamCreate(nil, self.streamCallBack, &context, self.monitoringPaths, FSEventStreamEventId(kFSEventStreamEventIdSinceNow), 0, FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents))!
  }
  
  public func start() {
    if stream == nil { constructStream() }
    FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
    FSEventStreamStart(stream)
  }
  
  
}
