//
//  URL+HiddenDetection.swift
//  TonnerreSearch
//
//  Created by Yaxin Cheng on 2018-12-19.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Foundation

extension URL {
  /// Check if the current fileURL is inside a package or a hidden folder
  var isInPackageOrHidden: Bool {
    let isPackageOrHidden: (URL)->Bool = {
      do {
        let resources = try $0.resourceValues(forKeys: [.isHiddenKey, .isPackageKey])
        return (resources.isHidden ?? false) || (resources.isPackage ?? false)
      } catch {
        return false
      }
    }
    var baseURL = URL(fileURLWithPath: "/")
    for pathComponent in deletingLastPathComponent().pathComponents.dropFirst() {
      baseURL.appendPathComponent(pathComponent)
      if isPackageOrHidden(baseURL) { return true }
    }
    return false
  }
  
  /// Check if the current fileURL is a hidden file
  var isHidden: Bool {
    do {
      let resources = try resourceValues(forKeys: [.isHiddenKey])
      return resources.isHidden ?? false
    } catch {
      return false
    }
  }
}
