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
    fileprivate var client: StompClient!
    fileprivate let socket = MockWebSocket()
    fileprivate var isDelegateMethodCalled = false
    fileprivate var receivedData: Data?
    fileprivate var receivedError: NSError?
    fileprivate var destination: String?
    
    override func setUp() {
        super.setUp()
        
        client = StompClient(socket: socket)
        client.delegate = self
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - Enabled Tests
    func testSetHeaderValue() {
        client.setValue("JSESSIONID=1234567890", forHeaderField: "Cookie")
        client.setValue("Bearer 1234567890", forHeaderField: "Authorization")
        
        XCTAssertNotNil(socket.headers["Cookie"])
        XCTAssertNotNil(socket.headers["Authorization"])
    }
    
    func testConnect() {
        let data = try! JSONSerialization.data(withJSONObject: ["CONNECTED\nheart-beat:0,0\nversion:1.1\n\n\0"], options: JSONSerialization.WritingOptions(rawValue: 0))
        socket.expectedMessage = "a" + String(data: data, encoding: String.Encoding.utf8)!
        
        client.connect()
        
        XCTAssert(socket.isMethodCalled)
        XCTAssert(isDelegateMethodCalled)
    }
    
    func testDisconnect() {
        let data = try! JSONSerialization.data(withJSONObject: ["CONNECTED\nheart-beat:0,0\nversion:1.1\n\n\0"], options: JSONSerialization.WritingOptions(rawValue: 0))
        socket.expectedMessage = "a" + String(data: data, encoding: String.Encoding.utf8)!
        socket.expectedError = NSError(domain: "com.nogle.surveillance", code: 999, userInfo: nil)
        
        client.disconnect()
        
        XCTAssert(socket.isMethodCalled)
        XCTAssertNotNil(receivedError)
    }
    
    func testSubscribe() {
        let body = ["key" : "value"]
        let bodyData = try! JSONSerialization.data(withJSONObject: body, options: JSONSerialization.WritingOptions(rawValue: 0))
        let bodyString = String(data: bodyData, encoding: String.Encoding.utf8)!
        let destination = "/user/topic/view/0"
        let data = try! JSONSerialization.data(withJSONObject: ["MESSAGE\ndestination:\(destination)\nsubscription:sub-0\nmessage-id:1234\ncontent-length:0\n\n\(bodyString)\n\0"], options: JSONSerialization.WritingOptions(rawValue: 0))
        socket.expectedMessage = "a" + String(data: data, encoding: String.Encoding.utf8)!
        
        _ = client.subscribe(destination, parameters: ["eid" : "5566"])
        
        XCTAssert(socket.isMethodCalled)
        XCTAssertNotNil(receivedData)
        XCTAssertEqual(self.destination, destination)
    }
    
    func testSubscribeWithError() {
        let data = try! JSONSerialization.data(withJSONObject: ["ERROR\nmessage:this is an error\ncontent-length:0\n\n\0"], options: JSONSerialization.WritingOptions(rawValue: 0))
        socket.expectedMessage = "a" + String(data: data, encoding: String.Encoding.utf8)!
        
        _ = client.subscribe("/path")
        
        XCTAssert(socket.isMethodCalled)
        XCTAssertNotNil(receivedError)
    }
    
    func testUnsubscribe() {
        let data = try! JSONSerialization.data(withJSONObject: ["CONNECTED\nheart-beat:0,0\nversion:1.1\n\n\0"], options: JSONSerialization.WritingOptions(rawValue: 0))
        socket.expectedMessage = "a" + String(data: data, encoding: String.Encoding.utf8)!
        
        client.unsubscribe("/path", destinationId: "sub-0")
        
        XCTAssert(socket.isMethodCalled)
    }
    
}

// MARK: - Stomp Client Delegate
extension StompClientTests {
    
    func stompClientDidConnected(_ client: StompClient) {
        isDelegateMethodCalled = true
    }
    
    func stompClient(_ client: StompClient, didErrorOccurred error: NSError) {
        receivedError = error
    }
    
    func stompClient(_ client: StompClient, didReceivedData data: Data, fromDestination destination: String) {
        receivedData = data
        self.destination = destination
    }
    
}

// MARK: - Mock WebSocket
class MockWebSocket: WebSocketProtocol {
    
    // MARK: - Private Properties
    private let url = URL(string: "https://developer.apple.com")!

    
    // MARK: - Public Properties
    weak var delegate: WebSocketDelegate?
    var headers: [String : String] = [:]
    var isConnected: Bool = false
    
    var isMethodCalled = false
    var expectedMessage: String!
    var expectedError: NSError!
    
    func connect() {
        isMethodCalled = true
        
        delegate?.websocketDidReceiveMessage(socket: WebSocket(url: url), text: expectedMessage)
    }
    
    func disconnect(_ forceTimeout: TimeInterval?) {
        isMethodCalled = true
        
        delegate?.websocketDidDisconnect(socket: WebSocket(url: url), error: expectedError)
    }
    
    func writeString(_ str: String) {
        isMethodCalled = true
        
        delegate?.websocketDidReceiveMessage(socket: WebSocket(url: url), text: expectedMessage)
    }
    
}
