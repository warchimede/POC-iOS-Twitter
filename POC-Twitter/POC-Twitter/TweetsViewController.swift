//
//  EmbedsViewController.swift
//  POC-Twitter
//
//  Created by William Archimède on 24/03/2020.
//  Copyright © 2020 William Archimede. All rights reserved.
//

import SafariServices
import UIKit
import WebKit

let TweetIds = [1240943034780520450, 1240596478663495681, 1242516361420640256, 1245651655594401792]

enum Callback: String {
  case height = "heightCallback"
}


class TweetsViewController: UITableViewController {

  let tweets = TweetsManager.shared
  let widgetsJs = WidgetsJsManager.shared

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "Tweets"

    // Set up tableview
    tableView.allowsSelection = false
    tableView.estimatedRowHeight = TweetCell.defaultCellHeight
    tableView.separatorStyle = .none

    tableView.register(TweetCell.self, forCellReuseIdentifier: TweetCell.identifier)

    initializeView(TweetIds)
  }

  func initializeView(_ tweetIds: [Int]) {
    tweets.initializeWithTweetIds(tweetIds)

    // Load widgets.js globally
    widgetsJs.load()

    // Preload WebViews before they are rendered
    preloadWebviews()
  }

  // WebView Management

  func preloadWebviews() {
    tweets.all().forEach { tweet in
      tweet.webView = createWebView(idx: tweet.idx)
    }
  }

  func createWebView(idx: Int) -> WKWebView {
    let webView = WKWebView()

    // Set delegates
    webView.navigationDelegate = self
    webView.uiDelegate = self

    // Register callbacks
    webView.configuration.userContentController.add(self, name: Callback.height.rawValue)

    // Set index as tag
    webView.tag = idx

    // Set initial frame
    webView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: CGFloat(TweetCell.defaultCellHeight))

    // Prevent scrolling
    webView.scrollView.isScrollEnabled = false

    // Load HTML template and set your domain
    webView.loadHTMLString(TweetCell.html, baseURL: URL(string: "https://france.tv")!)

    return webView
  }

  // UITableViewController

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return tweets.count()
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: TweetCell.identifier, for: indexPath)
    if let tweet = tweets.getByIdx(indexPath.row), let webView = tweet.webView {
      cell.contentView.addSubview(webView)
      cell.clipsToBounds = true
    }
    return cell
  }

  override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    cell.contentView.subviews.forEach { $0.removeFromSuperview() }
  }

  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if let tweet = tweets.getByIdx(indexPath.row) {
      return tweet.height
    }
    return TweetCell.defaultCellHeight
  }
}

// MARK:- Helpers
extension TweetsViewController {
  func updateHeight(idx: Int, height: CGFloat) {
    guard let tweet = tweets.getByIdx(idx)
      else { return }

    tweet.height = height + TweetCell.padding

    // Prevent UITableViewCells from jumping around an changing the scroll position as the resize
    tableView.reloadRowWithoutAnimation(IndexPath(row: idx, section: 0))
  }

  func openTweet(_ id: String) {
    if let url = URL(string: "https://twitter.com/i/status/\(id)") {
      openInSafarViewController(url)
    }
  }

  func openInSafarViewController(_ url: URL) {
    showDetailViewController(SFSafariViewController(url: url), sender: self)
  }
}

// MARK:- WKNavigationDelegate
extension TweetsViewController: WKNavigationDelegate {
  func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    if let url = navigationAction.request.url, navigationAction.navigationType == .linkActivated {
      openInSafarViewController(url)
      decisionHandler(.cancel)
    } else {
      decisionHandler(.allow)
    }
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    loadTweetInWebView(webView)
  }

  // Tweet Loader
  func loadTweetInWebView(_ webView: WKWebView) {
    guard let widgetsJsScript = widgetsJs.content,
      let tweet = tweets.getByIdx(webView.tag)
      else { return }

    webView.evaluateJavaScript(widgetsJsScript)
    webView.evaluateJavaScript("twttr.widgets.load();")

    // Documentation:
    // https://developer.twitter.com/en/docs/twitter-for-websites/embedded-tweets/guides/embedded-tweet-javascript-factory-function
    webView.evaluateJavaScript("""
      twttr.widgets.createTweet(
      '\(tweet.id)',
      document.getElementById('wrapper'),
      { align: 'center' }
      ).then(el => {
      window.webkit.messageHandlers.heightCallback.postMessage(el.offsetHeight.toString())
      });
      """)
  }
}

// MARK:- WKUIDelegate
extension TweetsViewController: WKUIDelegate {
  func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {

    // Allow links with target="_blank" to open in SafariViewController
    //   (includes clicks on the background of Embedded Tweets
    if let url = navigationAction.request.url, navigationAction.targetFrame == nil {
      openInSafarViewController(url)
    }

    return nil
  }
}

// MARK:- WKScriptMessageHandler
extension TweetsViewController: WKScriptMessageHandler {
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    guard let tag = message.webView?.tag,
      let body = message.body as? String,
      let height = Int(body),
      let callback = Callback(rawValue: message.name),
      callback == Callback.height
      else {
        return
    }

    updateHeight(idx: tag, height: CGFloat(height))
  }
}

// MARK:- UITableView
extension UITableView {
  func reloadRowWithoutAnimation(_ indexPath: IndexPath) {
    let lastScrollOffset = contentOffset
    UIView.performWithoutAnimation {
      reloadRows(at: [indexPath], with: .none)
    }
    setContentOffset(lastScrollOffset, animated: false)
  }
}
