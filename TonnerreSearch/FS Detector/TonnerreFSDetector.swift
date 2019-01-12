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
public class TonnerreFSDetector {
  private let monitoringPaths: CFArray
  private var stream: FSEventStreamRef! = nil
  private let streamCallBack: FSEventStreamCallback
  private let filterOptions: FilterOptions
  private let eventIdNow: FSEventStreamEventId
  private let callback: ([event])->Void
  /**
  The type of data returned in the callback. (path, [eventFlag])
  */
  public typealias event = (path: String, flags: TonnerreFSEvents)
  
  /**
   Constructe a File System Detector
   
   - Parameter paths: Any FS events happened in these pathes will be monitored
   - Parameter filterOptions: The options about which paths should be filtered out
   - Parameter callback: The call back function when FS event happens
   - Parameter events: The events detected by this detector
  */
  public convenience init(pathes: String...,
                          filterOptions: FilterOptions = [],
                          callback: @escaping (_ events: [event])->Void) {
    self.init(pathes: pathes, filterOptions: filterOptions, callback: callback)
  }
  
  /**
   Constructe a File System Detector
   
   - Parameter paths: Any FS events happened in these pathes will be monitored
   - Parameter filterOptions: The options about which paths should be filtered out
   - Parameter callback: The call back function when FS event happens
   - Parameter events: The events detected by this detector
   */
  public init(pathes: [String],
              filterOptions: FilterOptions = [],
              callback: @escaping (_ events: [event])->Void) {
    eventIdNow = FSEventStreamEventId(kFSEventStreamEventIdSinceNow)
    self.callback = callback
    self.filterOptions = filterOptions
    monitoringPaths = pathes.map{ $0 as CFString } as CFArray
    streamCallBack = { (stream, clientCallBackInfo, numEvents, eventPaths, eventFlags, eventIds) in
      guard let info = clientCallBackInfo else { return }
      // Take self from the callbackInfo. This is because, the block here is a C function, which needs some special treatment
      let mySelf = Unmanaged<TonnerreFSDetector>.fromOpaque(info).takeUnretainedValue()
      let cString = eventPaths.assumingMemoryBound(to: UnsafePointer<CChar>.self)// void* -> char**
      let filePaths = (0 ..< numEvents).map { String(cString: cString[$0]) }
      let fileFlags = (0 ..< numEvents).map { TonnerreFSEvents(rawValue: eventFlags[$0]) }
      let filteredEvents: [(String, TonnerreFSEvents)]
      if mySelf.filterOptions == .none {
        filteredEvents = zip(filePaths, fileFlags).map { ($0, $1) }
      } else {
        filteredEvents = zip(filePaths, fileFlags).filter {
          let fileURL = URL(fileURLWithPath: $0.0)
          return
            !(mySelf.filterOptions.contains(.skipHiddenItems) && fileURL.isHidden)
              &&
            !(mySelf.filterOptions.contains(.skipPakcageDescendants) && fileURL.isInPackage)
              &&
            !(mySelf.filterOptions.contains(.skipHiddenDescendants) && fileURL.isInHidden)
        }
      }
      let lastEventID = eventIds[numEvents - 1]
      UserDefaults.standard.set(lastEventID, forKey: "LastEventIDObserved")
      if filteredEvents.count == 0 { return }
      mySelf.callback(filteredEvents)
    }
  }
  
  /**
   Construct the stream object
  */
  private func constructStream() {
    let mySelf = Unmanaged.passRetained(self).toOpaque()// Convert `self` into a pointer, then keep to the context
    var context = FSEventStreamContext(version: 0, info: mySelf, retain: nil, release: nil, copyDescription: nil)
    let lastEventID = UserDefaults.standard.value(forKey: "LastEventIDObserved") as? FSEventStreamEventId ?? eventIdNow
    stream = FSEventStreamCreate(nil, self.streamCallBack, &context, self.monitoringPaths, lastEventID, 0, FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents))!
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
  
  /// Destructor which stops the stream
  deinit {
    stop()
  }
}
