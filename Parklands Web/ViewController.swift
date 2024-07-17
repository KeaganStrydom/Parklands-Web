//
//  ViewController.swift
//  Parklands Web
//
//  Created by Stephan Cilliers on 2017/05/16.
//  Copyright © 2017 Stephan Cilliers. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
	
	var webView: WKWebView!
	var tableView: UITableView!
	// var whitelistedSites: [String] = []
	var urlToLoad: URL?
	
	//	var webView: WKWebView!
	
	var searchBar: UIView!
	var searchField: UITextField!
	
	var backButton: UIBarButtonItem!
	var forwardButton: UIBarButtonItem!
	
	var heartButton: UIButton!//--------------heart********
	var whitelistedSites: [String] = []//--------------heart********
	var isTableViewVisible = false
	
	var homeButton: UIButton!
	var reloadButton: UIButton!
	
	var darkOrange: UIColor = UIColor(red: 250/255, green: 192/255, blue: 46/255, alpha: 1)
	
	var progressBarView: UIView!
	
	var pageEditorSource: String!
	
	var blockedWords: [String]?
	var blockedHosts: [String]?
	
	var requests: [()->()] = []
	var requestsToComplete: Int = 0
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Add requests to queue
		requests = [getBlockedWords, getBlockedHosts]
		requestsToComplete = requests.count
		
		// Execute requests
		let _ = requests.map { $0() }
		
		// Starting page
		let myURL = URL(string: "http://www.kiddle.co")
		let myRequest = URLRequest(url: myURL!)
		webView.load(myRequest)
		
		setupNavigationBar()
		
		
	}
	
	override func loadView() {
		super.loadView()
		
		// Create WebView
		webView = WKWebView(frame: .zero)
		webView.uiDelegate = self
		webView.navigationDelegate = self
		webView.allowsBackForwardNavigationGestures = true
		view = webView
		
		
	}
	
	// Load whitelist from file
	func loadWhitelist() {
		if let path = Bundle.main.path(forResource: "whitelisted-sites", ofType: "txt") {
			do {
				let content = try String(contentsOfFile: path, encoding: .utf8)
				whitelistedSites = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
			} catch {
				print("Error loading whitelist: \(error)")
			}
		}
	}
	
	// MARK: - TableView DataSource and Delegate Methods
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return whitelistedSites.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "WhitelistCell", for: indexPath)
		cell.textLabel?.text = whitelistedSites[indexPath.row]
		cell.backgroundColor = UIColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0) // Dark orange color
			  
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let selectedSite = whitelistedSites[indexPath.row]
		if let url = URL(string: selectedSite) {
			let request = URLRequest(url: url)
			
			webView.load(request)
		}
		// Hide the table view after selection
		   tableView.isHidden = true
		   
		   // Optionally deselect the row (for better UX)
		   tableView.deselectRow(at: indexPath, animated: true)
		
		
		// Extend the web view to fullscreen
		webView.frame = view.bounds
	}
	

	
	/* External resources */
	
	func getBlockedWords() {
		/*
		 -    Fetch words to be censored
		 */
		let endpoint = URL(string: "https://cdn.rawgit.com/stephancill/Parklands-Web/38650c09/blocked-words.txt")
		
		URLSession.shared.dataTask(with: endpoint!) { (data, response, error) in
			var words = String.init(data: data!, encoding: .utf8)?.components(separatedBy: "\n")
			let _ = words?.popLast()
			self.blockedWords = words
			self.asyncRequestComplete(error: error)
		}.resume()
	}
	
	func getBlockedHosts() {
		/*
		 -    Fetch blocked hosts
		 */
		let endpoint = URL(string: "https://cdn.rawgit.com/stephancill/Parklands-Web/38650c09/blocked-hosts.txt")
		
		URLSession.shared.dataTask(with: endpoint!) { (data, response, error) in
			var hosts = String.init(data: data!, encoding: .utf8)?.components(separatedBy: "\n")
			let _ = hosts?.popLast()
			self.blockedHosts = hosts
			self.asyncRequestComplete(error: error)
		}.resume()
	}
	
	
	
	func asyncRequestComplete(error: Error?) {
		/*
		 -    Handle complete request
		 */
		if error != nil {  return }
		requestsToComplete -= 1
		print("Requests remaining: ", requestsToComplete)
		if requestsToComplete == 0 {
			if let source = createPageEditorScript() {
				DispatchQueue.main.async {
					// Add source to webView
					let scriptPostLoad = WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
					self.webView.configuration.userContentController.addUserScript(scriptPostLoad)
					self.webView.configuration.userContentController.add(self, name: "enableUserInteraction")
					self.webView.configuration.userContentController.add(self, name: "disableUserInteraction")
				}
			}
		}
	}
	
	func createPageEditorScript() -> String? {
		/*
		 -    Populate the JS base script with external resources
		 */
		guard let hosts = blockedHosts, let words = blockedWords else {
			return nil
		}
		
		var source = ""
		source += "var words = \(words)\n"
		source += "var hosts = \(hosts)\n"
		do {
			if let path = Bundle.main.path(forResource: "page-editor", ofType:"js") {
				source += try String.init(contentsOf: URL(fileURLWithPath: path))
				return source
			} else {
				throw ScriptCreationError.creationFailure
			}
		} catch {
			print("Could not load words")
		}
		return nil
	}
	
	/* UI */
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		self.tearDownNavigationBar()
		self.setupNavigationBar()
	}
	
	
	
	
	/* Progress Bar */
	func startProgressBar() {
		progressBarView.backgroundColor = darkOrange
		progressBarView.setWidth(0)
		UIView.animate(withDuration: 2) {
			self.progressBarView.setWidth(self.view.frame.width - 100)
		}
	}
	
	func completeProgressBar() {
		UIView.animate(withDuration: 0.5) {
			self.progressBarView.setWidth(self.view.frame.width)
		}
		
		UIView.animate(withDuration: 0.5, animations: {
			self.progressBarView.backgroundColor = .clear
		}) { (bool) in
			self.progressBarView.setWidth(0)
		}
	}
	
	func cancelProgressBar() {
		UIView.animate(withDuration: 0.5, animations: {
			self.progressBarView.backgroundColor = .clear
		}) { (bool) in
			self.progressBarView.setWidth(0)
		}
	}
	
	func setupNavigationBar() {
		let bar = (self.navigationController?.navigationBar)!
		
		searchBar = UIView(frame: CGRect.init(x: 0, y: 0, width: 500, height: 30))
		if self.view.frame.width < 600 {
			searchBar.setWidth(self.view.frame.width * 40/100)
		}
		searchBar.frame.origin = CGPoint(x: bar.frame.width / 2 - searchBar.frame.width / 2, y: bar.frame.height / 2 - searchBar.frame.height / 2)
		searchBar.backgroundColor = .white
		searchBar.layer.cornerRadius = 7
		searchBar.layer.opacity = 0.75
		searchBar.layer.borderColor = darkOrange.cgColor
		searchBar.layer.shadowOffset = CGSize(width: 1, height: 1)
		searchBar.layer.shadowRadius = 2
		searchBar.layer.shadowColor = UIColor.gray.cgColor
		searchBar.layer.shadowOpacity = 0.0
		
		if self.view.frame.width < 600 {
			searchBar.setWidth(self.view.frame.width * 60/100)
		}
		
		searchField = UITextField(frame: CGRect.init(x: 0, y: 0, width: searchBar.frame.width * 95/100, height: 30))
		searchField.backgroundColor = .clear
		searchField.frame.origin = CGPoint(x: searchBar.frame.width / 2 - searchField.frame.width / 2, y: searchBar.frame.height / 2 - searchField.frame.height / 2)
		searchField.autocorrectionType = .no
		searchField.autocapitalizationType = .none
		searchField.keyboardType = .webSearch
		searchField.placeholder = "Search..."
		searchField.textAlignment = .center
		searchField.delegate = self
		searchBar.addSubview(searchField)
		
		backButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(goBack))
		backButton.tintColor = .orange
		backButton.isEnabled = false
		self.navigationItem.setLeftBarButton(backButton, animated: true)
		
		forwardButton = UIBarButtonItem(title: "Forward", style: .plain, target: self, action: #selector(goForward))
		forwardButton.tintColor = .orange
		forwardButton.isEnabled = false
		self.navigationItem.setRightBarButton(forwardButton, animated: true)
		//--------------HEART------------------------
		// Create the heart-shaped button
		heartButton = UIButton(frame: CGRect.init(x: 0, y: 0, width: searchBar.frame.height * 96/100-6, height: searchBar.frame.height * 96/100-6))
		heartButton.frame.origin = CGPoint(x: searchBar.frame.minX - heartButton.frame.width - 45, y: searchBar.frame.height / 2 - heartButton.frame.height / 2 + 7)
		heartButton.setImage(UIImage.init(named: "icn-heart"), for: .normal)
		heartButton.backgroundColor = .clear
		heartButton.addTarget(self, action: #selector(heartButtonTapped), for: .touchUpInside)
		searchBar.addSubview(heartButton)
		//----------------HEART----------------------
		
		homeButton = UIButton(frame: CGRect.init(x: 0, y: 0, width: searchBar.frame.height * 96/100, height: searchBar.frame.height * 96/100))
		homeButton.frame.origin = CGPoint(x: searchBar.frame.minX - homeButton.frame.width - 12, y: searchBar.frame.height / 2 - homeButton.frame.height / 2 + 7)
		homeButton.setImage(UIImage.init(named: "icn-home"), for: .normal)
		homeButton.addTarget(self, action: #selector(goHome), for: .touchUpInside)
		
		reloadButton = UIButton(frame: CGRect.init(x: 0, y: 0, width: searchBar.frame.height * 96/100, height: searchBar.frame.height * 96/100))
		reloadButton.frame.origin = CGPoint(x: searchBar.frame.maxX + reloadButton.frame.width - 20, y: searchBar.frame.height / 2 - reloadButton.frame.height / 2 + 6)
		reloadButton.setImage(UIImage.init(named: "icn-reload"), for: .normal)
		reloadButton.addTarget(self, action: #selector(reload), for: .touchUpInside)
		
		progressBarView = UIView(frame: CGRect.init(x: 0, y: searchBar.frame.maxY + 6, width: bar.frame.width, height: 3))
		progressBarView.backgroundColor = .blue
		progressBarView.setWidth(0)
		
		bar.barStyle = .default
		bar.tintColor = darkOrange
		bar.backgroundColor = darkOrange
		
		// Add subviews
		let _ = [searchBar,heartButton, homeButton, reloadButton, progressBarView].map { bar.addSubview($0) }
	}
	
	func tearDownNavigationBar() {
		for view in [searchBar,heartButton, homeButton, reloadButton, progressBarView] {
			view?.removeFromSuperview()
		}
	}
}

extension ViewController: WKUIDelegate, WKNavigationDelegate, WebViewTouchDelegate{
	
	
	/* WebKit */
	@objc func goBack() {
		webView.isUserInteractionEnabled = true
		self.webView.goBack()
	}
	
	@objc func goForward() {
		self.webView.goForward()
	}
	
	@objc func goHome() {
		self.searchField.text = ""
		self.webView.goHome()
	}
	@objc func heartButtonTapped() {
		
			
			// Initialize the web view
			webView = WKWebView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height * 0.05))
			webView.navigationDelegate = self
			view.addSubview(webView)
			
			// Load the URL if available
			if let url = urlToLoad {
				let request = URLRequest(url: url)
				webView.load(request)
			}
			
			// Load the whitelist from file
			loadWhitelist()
		if isTableViewVisible == false {
			isTableViewVisible.toggle()
			// Initialize the table view
			tableView = UITableView(frame: CGRect(x: 0, y: webView.frame.maxY, width: view.bounds.width, height: view.bounds.height * 0.95), style: .plain)
			tableView.delegate = self
			tableView.dataSource = self
			tableView.register(UITableViewCell.self, forCellReuseIdentifier: "WhitelistCell")
			tableView.backgroundColor = .clear
			
			
			view.addSubview(tableView)
		} else {
			isTableViewVisible.toggle()
			tableView.isHidden = true
			// Initialize the web view
			webView = WKWebView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height * 0.00))
			webView.navigationDelegate = self
			view.addSubview(webView)
			
			// Load the URL if available
			if let url = urlToLoad {
				let request = URLRequest(url: url)
				webView.load(request)
			}
		}
	
	
	}
	
	
	@objc func reload() {
		self.webView.load(URLRequest.init(url: self.webView.url!))
	}
	
	func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
		print("committed")
		backButton.isEnabled = webView.canGoBack
		forwardButton.isEnabled = webView.canGoForward
		
		startProgressBar()
	}
	
	func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
		print(error)
		cancelProgressBar()
		if (webView.canGoBack) {
			webView.goBack()
		}
	}
	
	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		print("finished")
		
		completeProgressBar()
	}
	
	func touchesBegan(webView: WKWebView) {
		self.searchField.endEditing(true)
	}
}

extension ViewController: WKScriptMessageHandler {
	func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
		print("hello")
		switch message.name {
		case "enableUserInteraction":
			webView.isUserInteractionEnabled = true
		case "disableUserInteraction":
			webView.isUserInteractionEnabled = false
		default:
			return
		}
	}
}

extension ViewController: UITextFieldDelegate {
	func textFieldDidBeginEditing(_ textField: UITextField) {
		textField.selectAll(self)
		searchBar.layer.shadowOpacity = 0.3
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		let text = textField.text!
		let escapedAddress = text.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
		let queryString = "http://www.kiddle.co/s.php?q=\(escapedAddress!)"
		
		startProgressBar()
		webView.load(queryString)
		textField.endEditing(true)
		return true
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		textField.textAlignment = .center
	}
	
	func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
		searchBar.layer.shadowOpacity = 0
	}
}



enum ScriptCreationError: Error {
	case creationFailure
}
