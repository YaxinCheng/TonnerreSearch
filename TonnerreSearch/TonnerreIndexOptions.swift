//
//  TonnerreIndexOptions.swift
//  TonnerreSearch
//
//  Created by Yaxin Cheng on 2018-04-22.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Foundation

public enum TonnerreSearchOptions: SKSearchOptions {
  case defaultOption = 0// By default, we add * for fuzzy after the query
  case noRelevanceScore = 1
  case spaceMeansOR = 2
  case findSimilar = 4
  case exactSearch = 5// Using the exact query passed in
  case headingFuzzy = 6// Add * before the query for fuzzy
}
