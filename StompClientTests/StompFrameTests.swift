//
//  StompFrameTests.swift
//  StompClient
//
//  Created by ShengHua Wu on 4/13/16.
//  Copyright © 2016 shenghuawu. All rights reserved.
//

import XCTest
@testable import StompClient

class StompFrameTests: XCTestCase {
    
    // MARK: - Private Properties
    fileprivate var frame: StompFrame!
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - Enabled Tests
    func testCreateSubscribeFrame() {
        let parameters = ["eid" : "5566", "mid" : "7788"]
        var headers: Set<StompHeader> = [.destination(path: "/path"), .destinationId(id: "sub-id")]
        for (key, value) in parameters {
            headers.insert(.custom(key: key, value: value))
        }
        frame = StompFrame(command: .Subscribe, headers: headers)
        
        XCTAssertEqual(frame.command, StompCommand.Subscribe)
        XCTAssertEqual(frame.headers.count, 4)
    }
    
    func testCreateFrameFromText() {
        let body = ["key" : "value"]
        let bodyData = try! JSONSerialization.data(withJSONObject: body, options: JSONSerialization.WritingOptions(rawValue: 0))
        let bodyString = String(data: bodyData, encoding: String.Encoding.utf8)!
        let data = try! JSONSerialization.data(withJSONObject: ["MESSAGE\ndestination:/user/topic/view/0\nsubscription:sub-0\nmessage-id:1234\ncontent-length:0\n\n\(bodyString)\n\0"], options: JSONSerialization.WritingOptions(rawValue: 0))
        let text = String(data: data, encoding: String.Encoding.utf8)!
        
        frame = try! StompFrame.parseText(text)
        
        XCTAssertEqual(frame.command, StompCommand.Message)
        XCTAssertEqual(frame.headers.count, 4)
        XCTAssertNotNil(frame.body)
    }
    
}
