//
//  TraderDesktopApiTests.swift
//  StompClient
//
//  Created by ShengHua Wu on 4/6/16.
//  Copyright © 2016 shenghuawu. All rights reserved.
//

import XCTest
import Starscream
@testable import StompClient

class TraderDesktopApiTests: XCTestCase {
    
    private var client: StompClient!
    private var socket: WebSocket!
    private let host = "http://10.1.20.28:8080"
    
    override func setUp() {
        super.setUp()
        
        let url = NSURL(string: host + "/traderdesktop")!.appendServerIdAndSessionId()
        socket = WebSocket(url: url)
        client = StompClient(socket: socket)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - Enabled Tests
    func testSubscribeAccountPNL() {
        let delegate = AccountPNLDelegate()
        delegate.expectation = expectationWithDescription("Subscribe account pnl")
        client.delegate = delegate

        let session = NSURLSession.sharedSession()
        let loginURLString = host + "/trader/desktop/auth/login"
        let request = NSMutableURLRequest(URL: NSURL(string: loginURLString)!)
        let param = ["id" : "shawn@nogle.com", "pass" : "Shawn123"]
//        var parts = [String]()
//        for (key, value) in param {
//            let field = key + "=" + value
//            parts.append(field)
//        }
//        let string = parts.joinWithSeparator("&")
//        let stringData = string.dataUsingEncoding(NSUTF8StringEncoding)!
        let data = try! NSJSONSerialization.dataWithJSONObject(param, options: NSJSONWritingOptions(rawValue: 0))
        request.HTTPMethod = "POST"
//        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = data
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            let res = response as! NSHTTPURLResponse
            if res.statusCode == 200 {
                self.parseCookies(res)
                
                self.client.connect()
            } else {
                debugPrint(res)
                XCTAssert(false, "Status code isn't 200")
                delegate.expectation.fulfill()
            }
        }
        task.resume()
     
        waitForExpectationsWithTimeout(500.0, handler: nil)
    }
    
    // MARK: - Private Methods
    private func parseCookies(res: NSHTTPURLResponse) {
        let fields = res.allHeaderFields as! [String : String]
        let cookies = NSHTTPCookie.cookiesWithResponseHeaderFields(fields, forURL: res.URL!)
        NSHTTPCookieStorage.sharedHTTPCookieStorage().setCookies(cookies, forURL: res.URL!, mainDocumentURL: nil)
        for cookie in cookies {
            var cookieProperties = [String: AnyObject]()
            cookieProperties[NSHTTPCookieName] = cookie.name
            cookieProperties[NSHTTPCookieValue] = cookie.value
            cookieProperties[NSHTTPCookieDomain] = cookie.domain
            cookieProperties[NSHTTPCookiePath] = cookie.path
            cookieProperties[NSHTTPCookieVersion] = NSNumber(integer: cookie.version)
            cookieProperties[NSHTTPCookieExpires] = NSDate().dateByAddingTimeInterval(31536000)
            
            let newCookie = NSHTTPCookie(properties: cookieProperties)
            NSHTTPCookieStorage.sharedHTTPCookieStorage().setCookie(newCookie!)
            
            print("name: \(cookie.name) value: \(cookie.value)")
        }
    }
    
}

// MARK: - Stub Delegate
class AccountPNLDelegate: NSObject, StompClientDelegate {
    
    // MARK: - Public Properties
    var expectation: XCTestExpectation!
    
    // MARK: - Private Properties
    private let destination = "/account/accountpnl/shawn@nogle.com"
    
    // MARK: - Stomp Client Delegate
    func stompClientDidConnected(client: StompClient) {
        client.subscribe(destination, parameters: nil)
    }
    
    func stompClient(client: StompClient, didErrorOccurred error: NSError) {
        XCTAssertTrue(false, "Error: \(error.localizedDescription)")
        expectation.fulfill()
    }
    
    func stompClient(client: StompClient, didReceivedData data: NSData) {
        let json = try! NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        debugPrint(json)
//        XCTAssert(json is [AnyObject], "Reveived data isn't an array.")
        
        client.unsubscribe(destination)
        
        XCTAssertNotNil(expectation, "Expectation doesn't setup.")
        expectation.fulfill()
    }
    
}
