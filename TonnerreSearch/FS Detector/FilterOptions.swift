//
//  FilterOptions.swift
//  TonnerreSearch
//
//  Created by Yaxin Cheng on 2018-12-20.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Foundation

/// A list of options that determins the filter for FSDetector
public struct FilterOptions: OptionSet {
  public typealias RawValue = UInt8
  public let rawValue: UInt8
  
  public init(rawValue: UInt8) {
    self.rawValue = rawValue
  }
  
  /// Filter out all the hidden files
  public static let hidden    = FilterOptions(rawValue: 1)//1
  /// Filter out all the paths directing inside a package
  public static let inPackage = FilterOptions(rawValue: 2)//10
  /// Filter out all the paths directing inside a hidden path
  public static let inHidden  = FilterOptions(rawValue: 4)//100
}
