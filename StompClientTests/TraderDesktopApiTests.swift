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
    private var jSession: String!
    private let baseURL = NSURL(string: "http://10.1.60.3:9090")!
    private let accoutId = "laphone"
    
    override func setUp() {
        super.setUp()
        
        logIn()
        
        let url = baseURL.URLByAppendingPathComponent("/traderdesktop").appendServerIdAndSessionId()
        socket = WebSocket(url: url)
        socket.headers["Cookie"] = jSession
        client = StompClient(socket: socket)
        
    }
    
    override func tearDown() {
        super.tearDown()
        
        logOut()
    }
    
    // MARK: - Disabled Tests
    func testSubscribeAccountPNL() {
        let delegate = AccountPNLDelegate()
        delegate.expectation = expectationWithDescription("Subscribe account pnl")
        client.delegate = delegate
        
        client.connect()
     
        waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testSubscribeMarginUsage() {
        let delegate = MarginUsageDelegate()
        delegate.expectation = expectationWithDescription("Subscribe margin usage")
        client.delegate = delegate
        
        client.connect()
        
        waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testSubscribeModelInfo() {
        let delegate = ModelInfoDelegate()
        delegate.expectation = expectationWithDescription("Subscribe model info")
        client.delegate = delegate
        
        client.connect()
        
        waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testSubscribeModelPNL() {
        let delegate = ModelPNLDelegate()
        delegate.expectation = expectationWithDescription("Subscribe model PNL")
        client.delegate = delegate
        
        client.connect()
        
        waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testSubscribeBlotter() {
        let delegate = BlotterDelegate()
        delegate.expectation = expectationWithDescription("Subscribe blotter")
        client.delegate = delegate
        
        client.connect()
        
        waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testSubscribeSymbolsPrice() {
        let delegate = SymbolsPriceDelegate()
        delegate.expectation = expectationWithDescription("Subscribe symbols price")
        client.delegate = delegate
        
        client.connect()
        
        waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    // MARK: - Private Methods
    private func logIn() {
        let expectation = expectationWithDescription("Log in")
        
        let session = NSURLSession.sharedSession()
        let url = baseURL.URLByAppendingPathComponent("/trader/desktop/auth/login")
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let param = ["id" : accoutId, "pass" : "laphone"]
        let data = try! NSJSONSerialization.dataWithJSONObject(param, options: NSJSONWritingOptions(rawValue: 0))
        request.HTTPBody = data
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            let res = response as! NSHTTPURLResponse
            if res.statusCode == 200 {
                let fields = res.allHeaderFields as! [String : String]
                let cookies = NSHTTPCookie.cookiesWithResponseHeaderFields(fields, forURL: res.URL!)
                let cookie = cookies.filter({
                    $0.name == "JSESSIONID"
                }).first!
                self.jSession = cookie.name + "=" + cookie.value
            } else {
                XCTAssert(false, "Status code isn't 200. Login failed.")
            }
            
            expectation.fulfill()
        }
        task.resume()
        
        waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    private func logOut() {
        let expectation = expectationWithDescription("Log out")
        
        let session = NSURLSession.sharedSession()
        let url = baseURL.URLByAppendingPathComponent("/trader/desktop/auth/logout")
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            let res = response as! NSHTTPURLResponse
            if res.statusCode != 200 {
                XCTAssert(false, "Status code isn't 200. Logout failed.")
            }
            
            expectation.fulfill()
        }
        task.resume()
        
        waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    // MARK: - Disabled Tests
    func disbale_testSubscribeTopicLog() {
        let delegate = TopicLogDelegate()
        delegate.expectation = expectationWithDescription("Subscribe topci log")
        client.delegate = delegate
        
        client.connect()
        
        waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func disable_testSubscribeSystemInfo() {
        let delegate = SystemInfoDelegate()
        delegate.expectation = expectationWithDescription("Subscribe system info")
        client.delegate = delegate
        
        client.connect()
        
        waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
}

// MARK: - Stub Delegate
class AccountPNLDelegate: NSObject, StompClientDelegate {
    
    // MARK: - Public Properties
    var expectation: XCTestExpectation?
    
    // MARK: - Private Properties
    private let destination = "/account/accountpnl/laphone"
    
    // MARK: - Stomp Client Delegate
    func stompClientDidConnected(client: StompClient) {
        client.subscribe(destination)
    }
    
    func stompClient(client: StompClient, didErrorOccurred error: NSError) {
        XCTAssertTrue(false, "Error: \(error.localizedDescription)")
        expectation?.fulfill()
    }
    
    func stompClient(client: StompClient, didReceivedData data: NSData) {
        let json = try! NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        XCTAssertEqual(json["accountId"], "laphone")
        XCTAssertNotNil(json["closePnl"])
        
        client.unsubscribe(destination)
        
        XCTAssertNotNil(expectation, "Expectation doesn't setup.")
        expectation?.fulfill()
        expectation = nil
    }
    
}

class MarginUsageDelegate: NSObject, StompClientDelegate {
    
    // MARK: - Public Properties
    var expectation: XCTestExpectation?
    
    // MARK: - Private Properties
    private let destination = "/account/marginusage/laphone"
    
    // MARK: - Stomp Client Delegate
    func stompClientDidConnected(client: StompClient) {
        client.subscribe(destination)
    }
    
    func stompClient(client: StompClient, didErrorOccurred error: NSError) {
        XCTAssertTrue(false, "Error: \(error.localizedDescription)")
        expectation?.fulfill()
    }
    
    func stompClient(client: StompClient, didReceivedData data: NSData) {
        let json = try! NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        XCTAssertEqual(json["accountId"], "laphone")
        XCTAssertNotNil(json["marginUsage"])
        
        client.unsubscribe(destination)
        
        XCTAssertNotNil(expectation, "Expectation doesn't setup.")
        expectation?.fulfill()
        expectation = nil
    }
    
}

class ModelInfoDelegate: NSObject, StompClientDelegate {
    
    // MARK: - Public Properties
    var expectation: XCTestExpectation?
    
    // MARK: - Private Properties
    private let destination = "/account/modelinfo/laphone"
    
    // MARK: - Stomp Client Delegate
    func stompClientDidConnected(client: StompClient) {
        client.subscribe(destination)
    }
    
    func stompClient(client: StompClient, didErrorOccurred error: NSError) {
        XCTAssertTrue(false, "Error: \(error.localizedDescription)")
        expectation?.fulfill()
    }
    
    func stompClient(client: StompClient, didReceivedData data: NSData) {
        let json = try! NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        XCTAssertNotNil(json["eid"])
        XCTAssertNotNil(json["modelName"])
        XCTAssertNotNil(json["modelId"])
        
        client.unsubscribe(destination)
        
        XCTAssertNotNil(expectation, "Expectation doesn't setup.")
        expectation?.fulfill()
        expectation = nil
    }
    
}

class SystemInfoDelegate: NSObject, StompClientDelegate {
    
    // MARK: - Public Properties
    var expectation: XCTestExpectation?
    
    // MARK: - Private Properties
    private let destination = "/account/sysinfo/laphone"
    
    // MARK: - Stomp Client Delegate
    func stompClientDidConnected(client: StompClient) {
        client.subscribe(destination)
    }
    
    func stompClient(client: StompClient, didErrorOccurred error: NSError) {
        XCTAssertTrue(false, "Error: \(error.localizedDescription)")
        expectation?.fulfill()
    }
    
    func stompClient(client: StompClient, didReceivedData data: NSData) {
        let json = try! NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        XCTAssertNotNil(json["eid"])
        XCTAssertNotNil(json["modelId"])
        XCTAssertNotNil(json["level"])
        
        client.unsubscribe(destination)
        
        XCTAssertNotNil(expectation, "Expectation doesn't setup.")
        expectation?.fulfill()
        expectation = nil
    }
    
}

class ModelPNLDelegate: NSObject, StompClientDelegate {
    
    // MARK: - Public Properties
    var expectation: XCTestExpectation?
    
    // MARK: - Private Properties
    private let destination = "/engine/modelpnl/5566/47"
    
    // MARK: - Stomp Client Delegate
    func stompClientDidConnected(client: StompClient) {
        client.subscribe(destination)
    }
    
    func stompClient(client: StompClient, didErrorOccurred error: NSError) {
        XCTAssertTrue(false, "Error: \(error.localizedDescription)")
        expectation?.fulfill()
    }
    
    func stompClient(client: StompClient, didReceivedData data: NSData) {
        let json = try! NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        XCTAssertEqual(json["modelId"], 47)
        XCTAssertNotNil(json["floatingPnl"])
        
        client.unsubscribe(destination)
        
        XCTAssertNotNil(expectation, "Expectation doesn't setup.")
        expectation?.fulfill()
        expectation = nil
    }
}

class BlotterDelegate: NSObject, StompClientDelegate {
    
    // MARK: - Public Properties
    var expectation: XCTestExpectation?
    
    // MARK: - Private Properties
    private let destination = "/engine/blotter/5566/47"
    
    // MARK: - Stomp Client Delegate
    func stompClientDidConnected(client: StompClient) {
        client.subscribe(destination)
    }
    
    func stompClient(client: StompClient, didErrorOccurred error: NSError) {
        XCTAssertTrue(false, "Error: \(error.localizedDescription)")
        expectation?.fulfill()
    }
    
    func stompClient(client: StompClient, didReceivedData data: NSData) {
        let json = try! NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        XCTAssert(json is [AnyObject])
        
        client.unsubscribe(destination)
        
        XCTAssertNotNil(expectation, "Expectation doesn't setup.")
        expectation?.fulfill()
        expectation = nil
    }
    
}

class SymbolsPriceDelegate: NSObject, StompClientDelegate {
    
    // MARK: - Public Properties
    var expectation: XCTestExpectation?
    
    // MARK: - Private Properties
    private let destination = "/symbol/symbols/price/cu1606"
    
    // MARK: - Stomp Client Delegate
    func stompClientDidConnected(client: StompClient) {
        client.subscribe(destination)
    }
    
    func stompClient(client: StompClient, didErrorOccurred error: NSError) {
        XCTAssertTrue(false, "Error: \(error.localizedDescription)")
        expectation?.fulfill()
    }
    
    func stompClient(client: StompClient, didReceivedData data: NSData) {
        let json = try! NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        XCTAssertEqual(json["symbol"], "cu1606")
        XCTAssertNotNil(json["time"])
        
        client.unsubscribe(destination)
        
        XCTAssertNotNil(expectation, "Expectation doesn't setup.")
        expectation?.fulfill()
        expectation = nil
    }
    
}

class TopicLogDelegate: NSObject, StompClientDelegate {
    
    // MARK: - Public Properties
    var expectation: XCTestExpectation?
    
    // MARK: - Private Properties
    private let destination = "/user/topic/log"
    
    // MARK: - Stomp Client Delegate
    func stompClientDidConnected(client: StompClient) {
        client.subscribe(destination, parameters: ["eid" : "5566", "mid" : "47"])
    }
    
    func stompClient(client: StompClient, didErrorOccurred error: NSError) {
        XCTAssertTrue(false, "Error: \(error.localizedDescription)")
        expectation?.fulfill()
    }
    
    func stompClient(client: StompClient, didReceivedData data: NSData) {
        let json = try! NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        XCTAssert(json is [AnyObject])
        
        client.unsubscribe(destination)
        
        XCTAssertNotNil(expectation, "Expectation doesn't setup.")
        expectation?.fulfill()
        expectation = nil
    }
    
}
