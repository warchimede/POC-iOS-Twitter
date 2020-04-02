//
//  WidgetJsManager.swift
//  POC-Twitter
//
//  Created by William Archimède on 02/04/2020.
//  Copyright © 2020 William Archimede. All rights reserved.
//

import Foundation

class WidgetsJsManager {
  static let shared = WidgetsJsManager()

  private(set) var content: String?

  func load() {
    do {
      content = try String(contentsOf: URL(string: "https://platform.twitter.com/widgets.js")!)
    } catch {
      print("Could not load widget.js script")
    }
  }
}
