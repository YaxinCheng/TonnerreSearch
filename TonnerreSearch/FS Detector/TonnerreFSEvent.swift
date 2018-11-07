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
  
  public static let created        = TonnerreFSEvents(rawValue: 0x100)
  public static let removed        = TonnerreFSEvents(rawValue: 0x200)
  public static let inodeModified  = TonnerreFSEvents(rawValue: 0x400)
  public static let renamed        = TonnerreFSEvents(rawValue: 0x800)
  public static let modified       = TonnerreFSEvents(rawValue: 0x1000)
  public static let finderModified = TonnerreFSEvents(rawValue: 0x2000)
  public static let changeOwner    = TonnerreFSEvents(rawValue: 0x4000)
  public static let XattrModified  = TonnerreFSEvents(rawValue: 0x8000)
  public static let isFile         = TonnerreFSEvents(rawValue: 0x10000)
  public static let isDirectory    = TonnerreFSEvents(rawValue: 0x20000)
  public static let isSymlink      = TonnerreFSEvents(rawValue: 0x40000)
}
