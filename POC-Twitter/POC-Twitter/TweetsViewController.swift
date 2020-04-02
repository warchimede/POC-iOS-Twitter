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

class TweetsViewController: UITableViewController {
  let tweetIds = [1240943034780520450, 1240596478663495681, 1242516361420640256, 1245651655594401792]
  private var tweetWebViews = Set<TweetWebView>()

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "Tweets"

    // Set up tableview
    tableView.allowsSelection = false
    tableView.estimatedRowHeight = TweetCell.defaultCellHeight
    tableView.separatorStyle = .none

    tableView.register(TweetCell.self, forCellReuseIdentifier: TweetCell.identifier)

    preloadWebviews()
  }

  // WebView Management

  func preloadWebviews() {
    tweetIds.forEach { tweetId in
      let tweetWebView = createTweetWebView(tweetId: tweetId)
      tweetWebView.loadHTML()
      tweetWebViews.insert(tweetWebView)
    }
  }

  func createTweetWebView(tweetId: Int) -> TweetWebView {
    let webView = TweetWebView()

    // Set delegates
    webView.navigationDelegate = self
    webView.uiDelegate = self

    // Register callbacks
    webView.configuration.userContentController.add(self, name: WebCallback.height.rawValue)

    // Set index as tag
    webView.tag = tweetId

    // Set initial frame
    webView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: CGFloat(TweetCell.defaultCellHeight))

    // Prevent scrolling
    webView.scrollView.isScrollEnabled = false

    return webView
  }

  // UITableViewController

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return tweetIds.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: TweetCell.identifier, for: indexPath)

    if let webView = tweetWebViews.first(where: { $0.tag == tweetIds[indexPath.row] }) {
      cell.contentView.addSubview(webView)
      cell.clipsToBounds = true
    }

    return cell
  }

  override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    cell.contentView.subviews.forEach { $0.removeFromSuperview() }
  }

  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

    guard let webView = tweetWebViews.first(where: { $0.tag == tweetIds[indexPath.row] })
      else { return TweetCell.defaultCellHeight }

    return webView.height
  }
}

// MARK:- Helpers
extension TweetsViewController {
  func updateHeight(tag: Int, height: CGFloat) {
    guard let webView = tweetWebViews.first(where: { $0.tag == tag }),
      let idx = tweetIds.firstIndex(of: tag)
    else { return }

    webView.height = height + TweetCell.padding

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
    guard let tweetWebView = webView as? TweetWebView else { return }

    tweetWebView.loadScripts(tweetId: tweetWebView.tag)
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
      let callback = WebCallback(rawValue: message.name),
      callback == WebCallback.height
      else {
        return
    }

    updateHeight(tag: tag, height: CGFloat(height))
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
