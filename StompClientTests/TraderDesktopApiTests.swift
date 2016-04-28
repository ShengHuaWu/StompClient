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
    private let baseURL = NSURL(string: "http://localhost:3000")!
    private let accoutId = "laphone"
    
    override func setUp() {
        super.setUp()
        
        let url = baseURL.URLByAppendingPathComponent("/traderdesktop").appendServerIdAndSessionId()
        client = StompClient(url: url)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - Enabled Tests
    func testSubscribeModelInfo() {
        let delegate = ModelInfoDelegate()
        delegate.expectation = expectationWithDescription("Subscribe model info")
        client.delegate = delegate
        
        client.connect()
        
        waitForExpectationsWithTimeout(500.0, handler: nil)
    }
    
    func testSubscribeBlotter() {
        let delegate = BlotterDelegate()
        delegate.expectation = expectationWithDescription("Subscribe blotter")
        client.delegate = delegate
        
        client.connect()
        
        waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
}

// MARK: - Stub Delegate
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
    
    func stompClient(client: StompClient, didReceivedData data: NSData, fromDestination destination: String) {
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

class BlotterDelegate: NSObject, StompClientDelegate {
    
    // MARK: - Public Properties
    var expectation: XCTestExpectation?
    
    // MARK: - Private Properties
    private let destination = "/engine/blotter/5566/55"
    
    // MARK: - Stomp Client Delegate
    func stompClientDidConnected(client: StompClient) {
        client.subscribe(destination)
    }
    
    func stompClient(client: StompClient, didErrorOccurred error: NSError) {
        XCTAssert(false, "Error: \(error.localizedDescription)")
        expectation?.fulfill()
    }
    
    func stompClient(client: StompClient, didReceivedData data: NSData, fromDestination destination: String) {
        let json = try! NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        XCTAssert(json is [AnyObject])
        
        client.unsubscribe(destination)
        
        XCTAssertNotNil(expectation, "Expectation doesn't setup.")
        expectation?.fulfill()
        expectation = nil
    }
    
}
