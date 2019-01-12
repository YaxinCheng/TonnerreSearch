//
//  TonnerreFSEvent.swift
//  TonnerreSearch
//
//  Created by Yaxin Cheng on 2018-04-23.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Foundation
import CoreServices

/**
 Tonnerre File System Event
 
 Several file system events that can be detected (e.g. created, removed, or modified...)
*/
public struct TonnerreFSEvents: OptionSet {
  public let rawValue: UInt32
  
  public init(rawValue: UInt32) {
    self.rawValue = rawValue
  }
  
  private init(rawValue: Int) {
    self.init(rawValue: UInt32(rawValue))
  }
  
  public static let created        = TonnerreFSEvents(rawValue: kFSEventStreamEventFlagItemCreated)
  public static let removed        = TonnerreFSEvents(rawValue: kFSEventStreamEventFlagItemRemoved)
  public static let inodeModified  = TonnerreFSEvents(rawValue: kFSEventStreamEventFlagItemInodeMetaMod)
  public static let renamed        = TonnerreFSEvents(rawValue: kFSEventStreamEventFlagItemRenamed)
  public static let modified       = TonnerreFSEvents(rawValue: kFSEventStreamEventFlagItemModified)
  public static let finderModified = TonnerreFSEvents(rawValue: kFSEventStreamEventFlagItemFinderInfoMod)
  public static let changeOwner    = TonnerreFSEvents(rawValue: kFSEventStreamEventFlagItemChangeOwner)
  public static let XattrModified  = TonnerreFSEvents(rawValue: kFSEventStreamEventFlagItemXattrMod)
  public static let isFile         = TonnerreFSEvents(rawValue: kFSEventStreamEventFlagItemIsFile)
  public static let isDirectory    = TonnerreFSEvents(rawValue: kFSEventStreamEventFlagItemIsDir)
  public static let isSymlink      = TonnerreFSEvents(rawValue: kFSEventStreamEventFlagItemIsSymlink)
  public static let isHardlink     = TonnerreFSEvents(rawValue: kFSEventStreamEventFlagItemIsHardlink)
  public static let isLastHardlink = TonnerreFSEvents(rawValue: kFSEventStreamEventFlagItemIsLastHardlink)
  public static let cloned         = TonnerreFSEvents(rawValue: kFSEventStreamEventFlagItemCloned)
}
