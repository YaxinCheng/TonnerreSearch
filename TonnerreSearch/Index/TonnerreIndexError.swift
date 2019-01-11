//
//  TonnerreIndexError.swift
//  TonnerreSearch
//
//  Created by Yaxin Cheng on 2018-04-22.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Foundation

public enum TonnerreIndexError: Error {
  /// Error occured during index file creation process
  ///
  /// Mainly caused by creating index at a path with an
  /// existing index file
  case fileCreateError
  /// Error occured during index file open process
  ///
  /// Possible cause may be trying to open an index
  /// with `writeAndRead` mode while
  /// there has already been an instance with the same
  /// mode opened.
  case fileOpenError
  case fileNotExist(atPath: String)
}
