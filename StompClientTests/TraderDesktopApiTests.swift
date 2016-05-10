//
//  TraderDesktopApiTests.swift
//  StompClient
//
//  Created by ShengHua Wu on 4/6/16.
//  Copyright © 2016 shenghuawu. All rights reserved.
//

import XCTest
@testable import StompClient

class TraderDesktopApiTests: XCTestCase {
    
    private var client: StompClient!
//    private let baseURL = NSURL(string: "http://localhost:3000")!
    private let baseURL = NSURL(string: "http://10.1.60.206:8080")!
    private let accoutId = "laphone"
    private var session: String!
    
    override func setUp() {
        super.setUp()
        
        let url = baseURL.URLByAppendingPathComponent("/traderdesktop").appendServerIdAndSessionId()
        client = StompClient(url: url)
        
        login()
        client.setValue(session, forHeaderField: "Cookie")
    }
    
    override func tearDown() {
        super.tearDown()
        
        logout()
    }
    
    // MARK: - Private Methods
    private func login() {
        let expectation = expectationWithDescription("Log in")
        
        let url = baseURL.URLByAppendingPathComponent("/trader/desktop/auth/login")
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        let params = ["id" : "laphone", "pass" : "laphone"]
        let body = try! NSJSONSerialization.dataWithJSONObject(params, options: NSJSONWritingOptions(rawValue: 0))
        request.HTTPBody = body
        NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
            NSOperationQueue.mainQueue().addOperationWithBlock {
                let res = response as! NSHTTPURLResponse
                let fields = res.allHeaderFields as! [String : String]
                let cookies = NSHTTPCookie.cookiesWithResponseHeaderFields(fields, forURL: res.URL!).filter { $0.name == "JSESSIONID" }
                if let cookie = cookies.first {
                    self.session = cookie.name + "=" + cookie.value
                }
                expectation.fulfill()
            }
        }.resume()
        
        waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    private func logout() {
        let url = baseURL.URLByAppendingPathComponent("/trader/desktop/auth/logout")
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        NSURLSession.sharedSession().dataTaskWithRequest(request).resume()
    }
    
    // MARK: - Enabled Tests
    func testSubscribeModelInfo() {
        let delegate = StubDelegate(destination: "/account/modelinfo/laphone") { data in
            let json = try! NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            XCTAssertNotNil(json["eid"])
            XCTAssertNotNil(json["modelName"])
            XCTAssertNotNil(json["modelId"])
        }
        delegate.expectation = expectationWithDescription("Subscribe model info")
        client.delegate = delegate
        
        client.connect()
        
        waitForExpectationsWithTimeout(500.0, handler: nil)
    }
    
    func testSubscribeBlotter() {
        let delegate = StubDelegate(destination: "/engine/blotter/5566/52") { data in
            let json = try! NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            XCTAssert(json is [AnyObject])
        }
        delegate.expectation = expectationWithDescription("Subscribe blotter")
        client.delegate = delegate
        
        client.connect()
        
        waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
}

// MARK: - Stub Delegate
class StubDelegate: NSObject, StompClientDelegate {
    
    // MARK: - Public Properties
    var expectation: XCTestExpectation?
    
    // MARK: - Private Properties
    private let destination: String
    private let assertionHandler: NSData -> Void
    private var destinationId: String?
    
    // MARK: - Designated Initializer
    init(destination: String, assertionHandler: NSData -> Void) {
        self.destination = destination
        self.assertionHandler = assertionHandler
        
        super.init()
    }
    
    // MARK: - Stomp Client Delegate
    func stompClientDidConnected(client: StompClient) {
        destinationId = client.subscribe(destination)
    }
    
    func stompClient(client: StompClient, didErrorOccurred error: NSError) {
        XCTAssert(false, "Error: \(error.localizedDescription)")
        expectation?.fulfill()
    }
    
    func stompClient(client: StompClient, didReceivedData data: NSData, fromDestination destination: String) {
        assertionHandler(data)
        
        client.unsubscribe(destination, destinationId: destinationId!)
        
        XCTAssertNotNil(expectation, "Expectation doesn't setup.")
        expectation?.fulfill()
        expectation = nil
    }
    
}
