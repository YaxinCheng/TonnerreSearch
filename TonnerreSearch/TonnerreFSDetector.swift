//
//  TonnerreFSDetector.swift
//  TonnerreSearch
//
//  Created by Yaxin Cheng on 2018-04-23.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Foundation
import CoreServices

/**
 Tonnerre File System Detector
 
 When a user initialize this object, and starts the stream, it detects the FS Events happened to the specified pathes. Whenever an event or several events happens, it passes the related events and pathes to the call back function
*/
class TonnerreFSDetector {
  private let monitoringPaths: CFArray
  private var stream: FSEventStreamRef! = nil
  private let streamCallBack: FSEventStreamCallback
  private let callback: ([event])->Void
  /**
  The type of data returned in the callback. (path, [eventFlag])
  */
  public typealias event = (path: String, flags: [TonnerreFSEvent])
  
  /**
   Constructe a File System Detector
   
   - Parameter paths: Any FS events happened in these pathes will be monitored
   - Parameter callback: The call back function when FS event happens
  */
  public init(pathes: String..., callback: @escaping ([event])->Void) {
    self.callback = callback
    monitoringPaths = pathes as CFArray
    streamCallBack = { (stream, clientCallBackInfo, numEvents, eventPaths, eventFlags, eventIds) in
      let cString = eventPaths.assumingMemoryBound(to: UnsafePointer<CChar>.self)// void* -> char**
      let filePaths = (0 ..< numEvents).map { String(cString: cString[$0]) }
      let fileFlags = (0 ..< numEvents).map { TonnerreFSEvent.segregate(flag: eventFlags[$0]) }
      let filteredEvents = zip(filePaths, fileFlags).filter {
        !($0.0.components(separatedBy: "/").last ?? "").starts(with: ".")
      }
      if let info = clientCallBackInfo {
        // Take self from the callbackInfo. This is because, the block here is a C function, which needs some special treatment
        let mySelf = Unmanaged<TonnerreFSDetector>.fromOpaque(info).takeUnretainedValue()
        mySelf.callback(filteredEvents)
      }
    }
  }
  
  /**
   Construct the stream object
  */
  private func constructStream() {
    let mySelf = Unmanaged.passRetained(self).toOpaque()// Convert `self` into a pointer, then keep to the context
    var context = FSEventStreamContext(version: 0, info: mySelf, retain: nil, release: nil, copyDescription: nil)
    stream = FSEventStreamCreate(nil, self.streamCallBack, &context, self.monitoringPaths, FSEventStreamEventId(kFSEventStreamEventIdSinceNow), 0, FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents))!
  }
  
  /**
   Run the detection stream
  */
  public func start() {
    if stream == nil { constructStream() }
    FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
    FSEventStreamStart(stream)
  }
  
  /**
   Stop the detection stream
  */
  public func stop() {
    if stream == nil { return }
    FSEventStreamStop(stream)
    FSEventStreamInvalidate(stream)
    FSEventStreamRelease(stream)
    stream = nil
  }
  
  /**
   Destructor which stops the stream
  */
  deinit {
    stop()
  }
}
