//
//  TonnerreIndexOptions.swift
//  TonnerreSearch
//
//  Created by Yaxin Cheng on 2018-04-22.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Foundation

public enum TonnerreIndexType {
  case nameOnly
  case metadata
}

public struct TonnerreSearchOptions: OptionSet {
  public var rawValue: SKSearchOptions
  
  public init(rawValue: SKSearchOptions) {
    self.rawValue = rawValue
  }
  
  public static let `default`        = TonnerreSearchOptions(rawValue: 0)
  public static let noRelevanceScore = TonnerreSearchOptions(rawValue: 1)
  public static let spaceMeansOR     = TonnerreSearchOptions(rawValue: 2)
  public static let findSimilar      = TonnerreSearchOptions(rawValue: 4)
}
