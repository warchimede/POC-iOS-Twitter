//
//  TweetWebView.swift
//  POC-Twitter
//
//  Created by William Archimède on 02/04/2020.
//  Copyright © 2020 William Archimede. All rights reserved.
//

import Foundation
import WebKit

class TweetWebView: WKWebView {
  private static let html = """
    <html>
    <head>
    <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'>
    </head>
    <body>
    <div id='wrapper'></div>
    </body>
    </html>
    """
  // Load widgets.js globally
  private static let widgetsScript: String? = try? String(contentsOf: URL(string: "https://platform.twitter.com/widgets.js")!)

  private static func loadScript(tweetId: Int) -> String {
    // Documentation:
    // https://developer.twitter.com/en/docs/twitter-for-websites/embedded-tweets/guides/embedded-tweet-javascript-factory-function
    return """
    twttr.widgets.load();
    twttr.widgets.createTweet(
    '\(tweetId)',
    document.getElementById('wrapper'),
    { align: 'center' }
    ).then(el => {
    window.webkit.messageHandlers.heightCallback.postMessage(el.offsetHeight.toString())
    });
    """
  }

  var height = TweetCell.defaultCellHeight

  func load(tweetId: Int) {
    guard let url = URL(string: "https://france.tv"),
      let widgetsScript = TweetWebView.widgetsScript
    else { return }

    loadHTMLString(TweetWebView.html, baseURL: url)

    evaluateJavaScript(widgetsScript)
    evaluateJavaScript(TweetWebView.loadScript(tweetId: tweetId))
  }
}
