//
//  StompClientTests.swift
//  StompClientTests
//
//  Created by ShengHua Wu on 3/31/16.
//  Copyright © 2016 shenghuawu. All rights reserved.
//

import XCTest
import Starscream
@testable import StompClient

class StompClientTests: XCTestCase, StompClientDelegate {
    
    // MARK: - Private Properties
    private var client: StompClient!
    private let socket = MockWebSocket()
    private var isDelegateMethodCalled = false
    private var receivedData: NSData?
    private var receivedError: NSError?
    
    override func setUp() {
        super.setUp()
        
        client = StompClient(socket: socket)
        client.delegate = self
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - Enabled Tests
    func testConnect() {
        let data = try! NSJSONSerialization.dataWithJSONObject(["CONNECTED\nheart-beat:0,0\nversion:1.1\n\n\0"], options: NSJSONWritingOptions(rawValue: 0))
        socket.expectedMessage = "a" + String(data: data, encoding: NSUTF8StringEncoding)!
        
        client.connect()
        
        XCTAssert(socket.isMethodCalled, "-connect method isn't called.")
        XCTAssert(isDelegateMethodCalled, "-stompClientDidConnected method isn't called.")
    }
    
    func testDisconnect() {
        let data = try! NSJSONSerialization.dataWithJSONObject(["CONNECTED\nheart-beat:0,0\nversion:1.1\n\n\0"], options: NSJSONWritingOptions(rawValue: 0))
        socket.expectedMessage = "a" + String(data: data, encoding: NSUTF8StringEncoding)!
        socket.expectedError = NSError(domain: "com.nogle.surveillance", code: 999, userInfo: nil)
        
        client.disconnect()
        
        XCTAssert(socket.isMethodCalled, "-disconnect method isn't called.")
        XCTAssertNotNil(receivedError, "Received error is empty.")
    }
    
    func testSubscribe() {
        let body = ["key" : "value"]
        let bodyData = try! NSJSONSerialization.dataWithJSONObject(body, options: NSJSONWritingOptions(rawValue: 0))
        let bodyString = String(data: bodyData, encoding: NSUTF8StringEncoding)!
        let data = try! NSJSONSerialization.dataWithJSONObject(["MESSAGE\ndestination:/user/topic/view/0\nsubscription:sub-0\nmessage-id:1234\ncontent-length:0\n\n\(bodyString)\n\0"], options: NSJSONWritingOptions(rawValue: 0))
        socket.expectedMessage = "a" + String(data: data, encoding: NSUTF8StringEncoding)!
        
        client.subscribe("/path", parameters: ["eid" : "5566"])
        
        XCTAssert(socket.isMethodCalled, "-writeString method isn't called.")
        XCTAssertNotNil(receivedData, "Received data is empty.")
    }
    
    func testSubscribeWithError() {
        let data = try! NSJSONSerialization.dataWithJSONObject(["ERROR\nmessage:this is an error\ncontent-length:0\n\n\0"], options: NSJSONWritingOptions(rawValue: 0))
        socket.expectedMessage = "a" + String(data: data, encoding: NSUTF8StringEncoding)!
        
        client.subscribe("/path")
        
        XCTAssert(socket.isMethodCalled, "-writeString method isn't called.")
        XCTAssertNotNil(receivedError, "Received error is empty.")
    }
    
    func testUnsubscribe() {
        let data = try! NSJSONSerialization.dataWithJSONObject(["CONNECTED\nheart-beat:0,0\nversion:1.1\n\n\0"], options: NSJSONWritingOptions(rawValue: 0))
        socket.expectedMessage = "a" + String(data: data, encoding: NSUTF8StringEncoding)!
        
        client.unsubscribe("/path")
        
        XCTAssert(socket.isMethodCalled, "-writeString method isn't called.")
    }
    
}

// MARK: - Stomp Client Delegate
extension StompClientTests {
    
    func stompClientDidConnected(client: StompClient) {
        isDelegateMethodCalled = true
    }
    
    func stompClient(client: StompClient, didErrorOccurred error: NSError) {
        receivedError = error
    }
    
    func stompClient(client: StompClient, didReceivedData data: NSData) {
        receivedData = data
    }
    
}

// MARK: - Mock WebSocket
class MockWebSocket: WebSocketProtocol {
    
    // MARK: - Public Properties
    weak var delegate: WebSocketDelegate?
    
    var isMethodCalled = false
    var expectedMessage: String!
    var expectedError: NSError!
    
    func connect() {
        isMethodCalled = true
        
        delegate?.websocketDidReceiveMessage(WebSocket(url: NSURL()), text: expectedMessage)
    }
    
    func disconnect(forceTimeout forceTimeout: NSTimeInterval?) {
        isMethodCalled = true
        
        delegate?.websocketDidDisconnect(WebSocket(url: NSURL()), error: expectedError)
    }
    
    func writeString(str: String) {
        isMethodCalled = true
        
        delegate?.websocketDidReceiveMessage(WebSocket(url: NSURL()), text: expectedMessage)
    }
    
}
