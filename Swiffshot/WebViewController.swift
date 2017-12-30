//
//  WebViewController.swift
//  Swiffshot
//
//  Created by Dmitry Kuklin on 23.12.16.
//  Copyright © 2016 Dmitry Kuklin. All rights reserved.
//

import UIKit

class WebViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var webView: UIWebView!
    
    var url: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = false
        webView.delegate = self
        webView.loadRequest(URLRequest(url: URL(string: url)!, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 10))
    }
    
    @IBAction func closePressed(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType == UIWebViewNavigationType.linkClicked {
            if (request.url!.host! == "redmanapps.com"){
                return true
            } else {
                UIApplication.shared.open(request.url!, options: [:], completionHandler: nil)
                return false
            }
        }
        return true
    }
}
