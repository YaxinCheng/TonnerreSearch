//
//  TonnerreIndexError.swift
//  TonnerreSearch
//
//  Created by Yaxin Cheng on 2018-04-22.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Foundation

public enum TonnerreIndexError: Error {
  case fileNotExist(atPath: String)
  case indexingError(atPath: String)
}
