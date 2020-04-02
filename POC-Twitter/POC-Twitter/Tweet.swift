//
//  Tweet.swift
//  POC-Twitter
//
//  Created by William Archimède on 02/04/2020.
//  Copyright © 2020 William Archimede. All rights reserved.
//

import Foundation

struct Tweet {
  // The tweet id
  let id: Int

  // An index value we'll use to map tweets to the WKWebViews tag property and the UITableView row
  let idx: Int

  init(id: Int, idx: Int) {
    self.id = id
    self.idx = idx
//    self.height = TweetCell.defaultCellHeight
  }
}
