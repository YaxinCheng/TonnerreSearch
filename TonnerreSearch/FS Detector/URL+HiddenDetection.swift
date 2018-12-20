//
//  URL+HiddenDetection.swift
//  TonnerreSearch
//
//  Created by Yaxin Cheng on 2018-12-19.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Foundation

extension URL {
  /// Returns true if the current fileURL is inside a package
  var isInPackage: Bool {
    let isPackage: (URL)->Bool = {
      do {
        let resources = try $0.resourceValues(forKeys: [.isPackageKey])
        return resources.isPackage ?? false
      } catch {
        return false
      }
    }
    var baseURL = URL(fileURLWithPath: "/")
    for pathComponent in deletingLastPathComponent().pathComponents.dropFirst() {
      baseURL.appendPathComponent(pathComponent)
      if isPackage(baseURL) { return true }
    }
    return false
  }
  
  /// Returns true if the current URL is inside a hidden directory
  var isInHidden: Bool {
    var baseURL = URL(fileURLWithPath: "/")
    for pathComponent in deletingPathExtension().pathComponents.dropFirst() {
      baseURL.appendPathComponent(pathComponent)
      if baseURL.isHidden { return true }
    }
    return false
  }
  
  /// Returns true if the current fileURL is a hidden file
  var isHidden: Bool {
    do {
      let resources = try resourceValues(forKeys: [.isHiddenKey])
      return resources.isHidden ?? false
    } catch {
      return false
    }
  }
}
