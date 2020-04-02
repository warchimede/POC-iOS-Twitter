//
//  TweetCell.swift
//  POC-Twitter
//
//  Created by William Archimède on 02/04/2020.
//  Copyright © 2020 William Archimede. All rights reserved.
//

import Foundation
import UIKit

class TweetCell: UITableViewCell {
  static let identifier = "TweetCell"
  static let defaultCellHeight: CGFloat = 1000
  static let padding: CGFloat = 20
  static let html = """
  <html>
  <head>
  <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'>
  </head>
  <body>
  <div id='wrapper'></div>
  </body>
  </html>
  """
}
