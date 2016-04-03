//
//  StompClient.swift
//  Surveillance
//
//  Created by ShengHua Wu on 3/23/16.
//  Copyright © 2016 nogle. All rights reserved.
//

import UIKit
import Starscream

public protocol WebSocketProtocol {
    
    weak var delegate: WebSocketDelegate? { get set }
    
    func connect()
    func disconnect(forceTimeout forceTimeout: NSTimeInterval?)
    func writeString(str: String)
    
}

extension WebSocket: WebSocketProtocol {

    public func writeString(str: String) {
        writeString(str, completion: nil)
    }
}

public protocol StompClientDelegate: NSObjectProtocol {
    
    func stompClientDidConnected(client: StompClient)
    func stompClient(client: StompClient, didErrorOccurred error: NSError)
    func stompClient(client: StompClient, didReceivedData data: NSData)
    
}

public class StompClient: NSObject, WebSocketDelegate {
    
    // MARK: - Public Properties
    public weak var delegate: StompClientDelegate?

    // MARK: - Private Properties
    private let socket: WebSocketProtocol
    
    // MARK: - Designated Initializer
    public init(socket: WebSocketProtocol) {
        self.socket = socket
        
        super.init()
        
        self.socket.delegate = self
    }
    
    // MARK: - Public Methods
    public func connect() {
        socket.connect()
    }
    
    public func disconnect() {
        sendDisconnect()
        socket.disconnect(forceTimeout: 0.0)
    }
    
    public func subscribe(destination: String, parameters: ParametersConvertible?) {
        let destinationId = "sub-" + NSNumber(integer: Int(arc4random()) % 1000).stringValue
        let command = StompSendingCommand.Subscribe(destination: destination, destinationId: destinationId, parameters: parameters)
        let frame = StompSendingFrame(command: command)
        sendFrame(frame)
    }
    
    public func unsubscribe(destination: String) {
        let command = StompSendingCommand.Unsubscribe(destination: destination)
        let frame = StompSendingFrame(command: command)
        sendFrame(frame)
    }
    
    // MARK: - Private Methods
    private func sendConnect() {
        let command = StompSendingCommand.Connect(acceptVersion: "1.1", heartBeat: "10000,10000")
        let frame = StompSendingFrame(command: command)
        sendFrame(frame)
    }
    
    private func sendDisconnect() {
        let command = StompSendingCommand.Disconnect
        let frame = StompSendingFrame(command: command)
        sendFrame(frame)
    }
    
    private func sendFrame(frame: StompSendingFrame) {
        do {
            let data = try NSJSONSerialization.dataWithJSONObject([frame.description], options: NSJSONWritingOptions(rawValue: 0))
            let string = String(data: data, encoding: NSUTF8StringEncoding)!
            // Because STOMP is a message convey protocol, only this delegate method
            // will be called, and we MUST use -writeString method to pass messages.
            socket.writeString(string)
        } catch let error as NSError {
            delegate?.stompClient(self, didErrorOccurred: error)
        }
    }
    
}

// MARK: - Websocket Delegate
extension StompClient {
    
    public func websocketDidConnect(socket: WebSocket) {
        // We should wait for server response an open type frame.
    }
    
    public func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        if let err = error {
            delegate?.stompClient(self, didErrorOccurred: err)
        }
    }
    
    public func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        let frame = StompResponseFrame(message: text)
        
        if frame.type == .Open {
            sendConnect()
            return
        } else if frame.type == .HeartBeat {
            return
        }
        
        switch frame.command {
        case .Connected:
            delegate?.stompClientDidConnected(self)
        case .Message(_, _, _, _, let body):
            let data = body.dataUsingEncoding(NSUTF8StringEncoding)!
            delegate?.stompClient(self, didReceivedData: data)
        case .Error(let message, _):
            let error = NSError(domain: "com.shenghuawu.StompClient", code: 999, userInfo: [NSLocalizedDescriptionKey : message])
            delegate?.stompClient(self, didErrorOccurred: error)
        default:
            break
        }
    }
    
    public func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        // This delegate will NOT be called, since STOMP is a message convey protocol.
    }
    
}

// MARK: - Parameters Convertible
public protocol ParametersConvertible: CustomStringConvertible {
    
    func toJSON() -> AnyObject
    
}

extension ParametersConvertible {
    
    var description: String {
        get {
            do {
                let data = try NSJSONSerialization.dataWithJSONObject(toJSON(), options: NSJSONWritingOptions(rawValue: 0))
                return String(data: data, encoding: NSUTF8StringEncoding)!
            } catch let error as NSError {
                debugPrint("convert to json data error: \(error.localizedDescription)")
                return ""
            }
        }
    }
    
}

// MARK: - Extensions
extension NSURL {
    
    func appendServerIdAndSessionId() -> NSURL {
        let serverId = NSNumber(integer: Int(arc4random()) % 1000).stringValue
        let sessionId = String.randomAlphaNumericString(8)
        var path = (serverId as NSString).stringByAppendingPathComponent(sessionId)
        path = (path as NSString).stringByAppendingPathComponent("websocket")
        
        return self.URLByAppendingPathComponent(path)
    }
    
}

extension String {
    
    static func randomAlphaNumericString(length: Int) -> String {
        let allowedChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let allowedCharsCount = UInt32(allowedChars.characters.count)
        var randomString = ""
        
        for _ in (0 ..< length) {
            let randomNum = Int(arc4random_uniform(allowedCharsCount))
            let newCharacter = allowedChars[allowedChars.startIndex.advancedBy(randomNum)]
            randomString += String(newCharacter)
        }
        
        return randomString
    }
    
}
