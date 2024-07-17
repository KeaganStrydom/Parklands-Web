//
//  Extensions.swift
//  Parklands Web
//
//  Created by Stephan Cilliers on 2017/08/27.
//  Copyright © 2017 Stephan Cilliers. All rights reserved.
//

import UIKit
import WebKit

extension WKWebView {
	func load(_ link: String) {
		let myURL = URL(string: link)
		let myRequest = URLRequest(url: myURL!)
		self.load(myRequest)
	}
	
	func goHome() {
		let currentPage = self.url?.absoluteString
		if currentPage != "http://m.kiddle.co/" {
			load("http://m.kiddle.co/")
		}
	}
    

	
	open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		self.touchesBegan(touches, with: event)
		if let delegate = self.uiDelegate as? WebViewTouchDelegate {
			delegate.touchesBegan(webView: self)
		}
	}
    
    
}



protocol WebViewTouchDelegate {
	func touchesBegan(webView: WKWebView)
}

extension UIView {
	func setWidth(_ width: CGFloat) {
		self.frame = CGRect(origin: self.frame.origin, size: CGSize.init(width: width, height: self.frame.height))
	}
}
