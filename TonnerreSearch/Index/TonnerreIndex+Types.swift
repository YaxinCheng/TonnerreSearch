//
//  TonnerreIndex+Types.swift
//  TonnerreSearch
//
//  Created by Yaxin Cheng on 2019-01-10.
//  Copyright © 2019 Yaxin Cheng. All rights reserved.
//

import Foundation

public extension TonnerreIndex {
  /// Search options used for searching documents from the index
  struct SearchOptions: OptionSet {
    public var rawValue: SKSearchOptions
    
    public init(rawValue: SKSearchOptions) {
      self.rawValue = rawValue
    }
    
    private init(rawValue: Int) {
      self.init(rawValue: SKSearchOptions(rawValue))
    }
    
    public static let `default`        = SearchOptions(rawValue: kSKSearchOptionDefault)
    public static let noRelevanceScore = SearchOptions(rawValue: kSKSearchOptionNoRelevanceScores)
    public static let spaceMeansOR     = SearchOptions(rawValue: kSKSearchOptionSpaceMeansOR)
    public static let findSimilar      = SearchOptions(rawValue: kSKSearchOptionFindSimilar)
  }
  
  /// Open an index readonly or writable
  enum OpenMode {
    /// Open the index with readOnly mode
    /// - note: in this mode, all `writeDocument` and
    /// `removeDocument` actions will be ignored
    case readOnly
    /// Open the index with write and read mode
    /// - note: only one instance with `writeAndRead` mode is allowed
    /// . Trying to open a second instance with this mode would throw
    /// an error
    case writeAndRead
    
    var rawValue: Bool {
      switch self {
      case .readOnly: return false
      case .writeAndRead: return true
      }
    }
  }
  
  /// Either adding file name or file content data to the index
  enum ContentType {
    /// full file name with extensions
    case fileName
    /// file name without extensions
    ///
    /// `Safari.app` -> `Safari`
    case cleanedFileName
    /// File content
    case fileContent
  }
}
