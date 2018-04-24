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
enum TonnerreFSEvent: UInt32 {
  case created        = 0x100
  case removed        = 0x200
  case inodeModified  = 0x400
  case renamed        = 0x800
  case modified       = 0x1000
  case finderModified = 0x2000
  case changeOwner    = 0x4000
  case XattrModified  = 0x8000
  case isFile         = 0x10000
  case isDirectory    = 0x20000
  case isSymlink      = 0x40000
  
  private static func & (lhs: UInt32, rhs: TonnerreFSEvent) -> UInt32 {
    return lhs & rhs.rawValue
  }
  
  /**
   Segregate one mixed UInt32 type flag into multiple TonnerreFSEvents
   
   - Parameter flag: the | (or) connected mixed flag
   - Returns: an array of TonnerreFSEvent retreived from the mixed flag
  */
  static func segregate(flag: UInt32) -> [TonnerreFSEvent] {
    return (0 ..< 11).map({// Generate all possible TonnerreFSEvent UInt32 values, then & with the flag
      flag & (0x100 * (pow(2, $0) as NSDecimalNumber).uint32Value)
    }).filter({ $0 != 0}).compactMap(TonnerreFSEvent.init)
  }
}
