//
//  TonnerreIndexError.swift
//  TonnerreSearch
//
//  Created by Yaxin Cheng on 2018-04-22.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Foundation

public enum TonnerreIndexError: Error {
  case fileCreateError
  case fileOpenError
  case fileNotExist(atPath: String)
}
