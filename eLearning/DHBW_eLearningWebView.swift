//
//  DHBW_eLearningWebView.swift
//  DHBW Stuttgart
//
//  Created by Yannik Ehlert on 26.10.16.
//  Copyright © 2016 Yannik Ehlert. All rights reserved.
//

#if os(iOS)
    import UIKit
    import MBProgressHUD
    import QuickLook
#elseif os(macOS)
    import Cocoa
    import ProgressKit
#endif

import WebKit
import Alamofire

class DHBW_eLearningWebView: DHViewController, WKNavigationDelegate {
    var webView : WKWebView! = nil
    var httpCookies = [HTTPCookie]()
    let configuration = WKWebViewConfiguration()
    var cookieString = ""
    var userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 10_1_1 like Mac OS X) AppleWebKit/602.2.14 (KHTML, like Gecko) Mobile/14B100"
    var authenticated = false
    var alamoSession : Alamofire.SessionManager! = nil
    #if os(macOS)
    @IBOutlet weak var pview: CircularProgressView!
    #endif
    
    // Newly downloaded file
    var downloadedFile : URL? = nil
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView = WKWebView(frame: view.frame, configuration: configuration)
        // Alamofire.Manager.sharedInstance.session.configuration
        webView.frame = view.frame
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        
        navigationTitle = "Authentifizierung…".localized
        #if os(macOS)
            pview.isHidden = true
            pview.strokeWidth = 7
            pview.showPercent = false
            pview.progress = 0
            pview.animated = true
        #endif
        view.addSubview(webView)
        webView.evaluateJavaScript("navigator.userAgent", completionHandler: { (reply, error) -> Void in
            guard let reply = reply else {
                return
            }
            if let userReply = reply as? String {
                self.userAgent = userReply
            }
        })
        
        #if os(macOS)
            view.addSubview(pview)
        #endif
        
        let request = URLRequest(url: URL(string: "https://elearning.dhbw-stuttgart.de/")!)
        webView.load(request)
    }
    #if os(iOS)
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        DHErrorPresenter.add(viewController: self, error: error)
    }
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    override func viewWillAppear(_ animated: Bool) {
        BarButtonSettings.shared(controller: navigationController).setbutton(self)
    }
    #elseif os(macOS)
    override func viewDidAppear() {
        super.viewDidAppear()
        NotificationCenter.default.addObserver(self, selector: #selector(DHBW_eLearningWebView.reload), name: NSNotification.Name(rawValue: DHMacMenuNotification.refresh.rawValue), object: nil)
    }
    override func viewDidDisappear() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: DHMacMenuNotification.refresh.rawValue), object: nil)
    }
    #endif
    func reload() {
        webView.reload()
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
        guard let response = navigationResponse.response as? HTTPURLResponse else {
            return
        }
        guard let headerFields = response.allHeaderFields as? [String : String], let url = response.url else {
            return
        }
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
        httpCookies += cookies
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // https://elearning.dhbw-stuttgart.de/moodle/pluginfile.php/58230/mod_resource/content/1/bwl7_skript_Stuttgart_Studenten.pdf
        if navigationAction.request.url?.absoluteString.range(of: "https://elearning.dhbw-stuttgart.de/moodle/pluginfile.php") != nil {
            // HUD progress
            #if os(iOS)
                let hud = MBProgressHUD.showAdded(to: view, animated: true)
                hud.mode = .annularDeterminate
                hud.label.text = "Download läuft…".localized
            #elseif os(macOS)
                DispatchQueue.main.async {
                    self.pview.isHidden = false
                }
            #endif
            
            decisionHandler(.cancel)
            configuration.processPool = WKProcessPool()
            guard let url = navigationAction.request.url else {
                return
            }
            let sepArray = url.absoluteString.components(separatedBy: "/")
            let fileName = sepArray[sepArray.count - 1].replacingOccurrences(of: "?forcedownload=1", with: "").removingPercentEncoding!
            let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
            let destination: DownloadRequest.DownloadFileDestination = { _, _ in
                return (fileURL, [.removePreviousFile])
            }
            let aConfiguration = URLSessionConfiguration.default
            aConfiguration.timeoutIntervalForRequest = 20
            aConfiguration.httpAdditionalHeaders = ["User-Agent": userAgent, "Cookie": cookieString]
            alamoSession = Alamofire.SessionManager(configuration: aConfiguration)
            alamoSession.startRequestsImmediately = true
            
            #if os(iOS)
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            #endif
            alamoSession.download(url.absoluteString, to: destination).response { response in
                #if os(iOS)
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    hud.hide(animated: true)
                    if response.error == nil, let _ = response.destinationURL?.path {
                        DispatchQueue.main.async {
                            self.downloadedFile = fileURL
                            let prevcontroller = QLPreviewController()
                            prevcontroller.delegate = self
                            prevcontroller.dataSource = self
                            self.present(prevcontroller, animated: true, completion: nil)
                        }
                    } else if let error = response.error {
                        DHErrorPresenter.add(viewController: self, error: error)
                    }
                #elseif os(macOS)
                    DispatchQueue.main.async {
                        self.pview.isHidden = true
                        self.pview.progress = 0
                    }
                    NSWorkspace.shared().open(fileURL)
                #endif
                }.downloadProgress { progress in
                    #if os(iOS)
                        hud.progress = Float(progress.fractionCompleted)
                    #elseif os(macOS)
                        DispatchQueue.main.async {
                            self.pview.progress = CGFloat(progress.fractionCompleted)
                        }
                    #endif
            }
        } else {
            decisionHandler(WKNavigationActionPolicy.allow)
        }
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        #if os(iOS)
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        #endif
        webView.evaluateJavaScript("document.cookie", completionHandler: { (response,error) -> Void in
            guard let response = response else {
                return
            }
            guard let cookies = response as? String else {
                return
            }
            self.cookieString = cookies
        })
        if webView.url?.absoluteString.range(of: "https://saml.dhbw-stuttgart.de") != nil {
            navigationTitle = "Authentifizierung…".localized
        } else {
            navigationTitle = webView.title
        }
        if webView.url?.absoluteString == "https://saml.dhbw-stuttgart.de/idp/Authn/UserPassword" {
            webView.evaluateJavaScript("document.documentElement.outerHTML.toString()", completionHandler: { (response, error) -> Void in
                guard let response = response, let html = response as? String else {
                    return
                }
                if html.range(of: "DHBW-Lehre-eMail-Adresse oder Passwort falsch.") != nil {
                    DHErrorPresenter.add(viewController: self, error: "Der Benutzername oder das Passwort ist falsch.".localized)
                    return
                }
                let js = "$('j_username').value = '"
                    + SharedSettings.shared.lehreUsernameWithMail.replacingOccurrences(of: "'", with: "\\'")
                    + "';document.getElementsByName('j_password')[0].value = '"
                    + SharedSettings.shared.lehrePassword.replacingOccurrences(of: "'", with: "\\'")
                    + "';$('login').submit();"
                
                webView.evaluateJavaScript(js, completionHandler: nil)
            })
        } else if webView.url?.absoluteString.range(of: "https://elearning.dhbw-stuttgart.de/") != nil && !authenticated {
            authenticated = true
        } else if webView.url?.absoluteString.range(of: "https://saml.dhbw-stuttgart.de/") != nil && authenticated {
            webView.load(URLRequest(url: URL(string: "https://elearning.dhbw-stuttgart.de/")!))
        }
        if webView.url?.absoluteString.range(of: "https://elearning.dhbw-stuttgart.de/moodle/course/view.php") != nil {
            webView.evaluateJavaScript("var eles = document.getElementsByTagName('a');for (var i=0;i < eles.length; i++)eles[i].onclick = null;", completionHandler: nil)
        } else if webView.url?.absoluteString.range(of: "https://elearning.dhbw-stuttgart.de/moodle/mod/resource/view.php") != nil {
            // Link weiterhin klickbar machen
            webView.evaluateJavaScript("var eles = document.getElementsByTagName('a');for (var i=0;i < eles.length; i++)eles[i].onclick = null;", completionHandler: nil)
            // Klicken Sie auf den Link '<a href="
            webView.evaluateJavaScript("document.documentElement.outerHTML.toString()", completionHandler: { (response, error) -> Void in
                guard let response = response else {
                    return
                }
                guard let html = response as? String else {
                    return
                }
                let split = html.components(separatedBy: "Klicken Sie auf den Link '<a href=\"")
                if split.count < 2 {
                    return
                }
                let urlToOpen = split[1].components(separatedBy: "\"")[0]
                webView.evaluateJavaScript("window.location.href = \"" + urlToOpen + "\"", completionHandler: nil)
            })
        }
    }
    #if os(iOS)
    override func viewDidLayoutSubviews() {
        webView.frame = view.frame
    }
    #elseif os(macOS)
    override func viewDidLayout() {
        webView.frame = view.frame
        pview.frame = NSRect(x: NSMidX(view.frame) - 50.5, y: NSMidY(view.frame) - 50.5, width: 101, height: 101)
    }
    #endif
}
