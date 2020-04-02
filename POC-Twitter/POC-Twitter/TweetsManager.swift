//
//  TweetsManager.swift
//  POC-Twitter
//
//  Created by William Archimède on 02/04/2020.
//  Copyright © 2020 William Archimede. All rights reserved.
//

import Foundation

class TweetsManager {
  static let shared = TweetsManager()

  var tweets: [Tweet] = []

  func initializeWithTweetIds(_ tweetIds: [Int]) {
    tweets = buildIndexedTweets(tweetIds)
  }

  func count() -> Int {
    return tweets.count
  }

  func all() -> [Tweet] {
    return tweets
  }

  func getByIdx(_ idx: Int) -> Tweet? {
    return tweets.first { $0.idx == idx }
  }

  private func buildIndexedTweets(_ tweetIds: [Int]) -> [Tweet] {
    return tweetIds.enumerated().map { (idx, id) in
      return Tweet(id: id, idx: idx)
    }
  }
}
