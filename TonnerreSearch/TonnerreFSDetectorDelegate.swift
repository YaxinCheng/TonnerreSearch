//
//  TonnerreFSDetectorDelegate.swift
//  TonnerreSearch
//
//  Created by Yaxin Cheng on 2018-04-23.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Foundation

protocol TonnerreFSDetectorDelegate: class {
  func fileEventsOccured(events: [TonnerreFSDetector.event])
}
