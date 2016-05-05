//
//  StompClient.swift
//  Surveillance
//
//  Created by ShengHua Wu on 3/23/16.
//  Copyright © 2016 nogle. All rights reserved.
//

import UIKit
import Starscream

public protocol StompClientDelegate: NSObjectProtocol {
    
    func stompClientDidConnected(client: StompClient)
    func stompClient(client: StompClient, didErrorOccurred error: NSError)
    func stompClient(client: StompClient, didReceivedData data: NSData, fromDestination destination: String)
    
}

public class StompClient: NSObject, WebSocketDelegate {
    
    // MARK: - Public Properties
    public weak var delegate: StompClientDelegate?
    public var isConnected: Bool {
        return socket.isConnected
    }

    // MARK: - Private Properties
    private var socket: WebSocketProtocol
    
    // MARK: - Designated Initializer
    public init(socket: WebSocketProtocol) {
        self.socket = socket
        
        super.init()
        
        self.socket.delegate = self
    }
    
    // MARK: - Convenience Initializer
    public convenience init(url: NSURL) {
        let socket = WebSocket(url: url)
        self.init(socket: socket)
    }
    
    // MARK: - Public Methods
    public func setValue(value: String, forHeaderField field: String) {
        socket.headers[field] = value
    }
    
    public func connect() {
        socket.connect()
    }
    
    public func disconnect() {
        sendDisconnect()
        socket.disconnect(forceTimeout: 0.0)
    }
    
    public func subscribe(destination: String, parameters: [String : String]? = nil) {
        let id = "sub-" + Int(arc4random_uniform(1000)).description
        var headers:Set<StompHeader> = [.DestinationId(id: id), .Destination(path: destination)]
        if let params = parameters where !params.isEmpty {
            for (key, value) in params {
                headers.insert(.Custom(key: key, value: value))
            }
        }
        let frame = StompFrame(command: .Subscribe, headers: headers)
        sendFrame(frame)
    }

    public func unsubscribe(destination: String) {
        let frame = StompFrame(command: .Unsubscribe, headers: [.Destination(path: destination)])
        sendFrame(frame)
    }
    
    // MARK: - Private Methods
    private func sendConnect() {
        let headers: Set<StompHeader> = [.AcceptVersion(version: "1.1"), .HeartBeat(value: "10000,10000")]
        let frame = StompFrame(command: .Connect, headers: headers)
        sendFrame(frame)
    }
    
    private func sendDisconnect() {
        let frame = StompFrame(command: .Disconnect)
        sendFrame(frame)
    }
    
    private func sendFrame(frame: StompFrame) {
        let data = try! NSJSONSerialization.dataWithJSONObject([frame.description], options: NSJSONWritingOptions(rawValue: 0))
        let string = String(data: data, encoding: NSUTF8StringEncoding)!
        // Because STOMP is a message convey protocol, only this delegate method
        // will be called, and we MUST use -writeString method to pass messages.
        socket.writeString(string)
    }
    
}

// MARK: - Websocket Delegate
extension StompClient {
    
    public func websocketDidConnect(socket: WebSocket) {
        // We should wait for server response an open type frame.
    }
    
    public func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        if let error = error {
            delegate?.stompClient(self, didErrorOccurred: error)
        }
    }
    
    public func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        var mutableText = text
        let firstCharacter = mutableText.removeAtIndex(mutableText.startIndex)
        do {
            // Parse response type from the first character
            let type = try StompResponseType.parseCharacter(firstCharacter)
            if type == .Open {
                sendConnect()
                return
            } else if type == .HeartBeat {
                // TODO: Send heart-beat back to server.
                return
            }
            
            // Parse frame from the remaining text
            let frame = try StompFrame.parseText(mutableText)
            switch frame.command {
            case .Connected:
                delegate?.stompClientDidConnected(self)
            case .Message:
                guard let data = frame.body?.dataUsingEncoding(NSUTF8StringEncoding) else {
                    return
                }
                
                delegate?.stompClient(self, didReceivedData: data, fromDestination: frame.destination)
            case .Error:
                let error = NSError(domain: "com.shenghuawu.error", code: 999, userInfo: [NSLocalizedDescriptionKey : frame.message])
                delegate?.stompClient(self, didErrorOccurred: error)
            default:
                break
            }
        } catch let error as NSError {
            delegate?.stompClient(self, didErrorOccurred: error)
        }
    }
    
    public func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        // This delegate will NOT be called, since STOMP is a message convey protocol.
    }
    
}

// MARK: - Extensions
extension NSURL {
    
    func appendServerIdAndSessionId() -> NSURL {
        let serverId = Int(arc4random_uniform(1000)).description
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

public protocol WebSocketProtocol {
    
    weak var delegate: WebSocketDelegate? { get set }
    var headers: [String : String] { get set }
    var isConnected: Bool { get }
    
    func connect()
    func disconnect(forceTimeout forceTimeout: NSTimeInterval?)
    func writeString(str: String)
    
}

extension WebSocket: WebSocketProtocol {
    
    public func writeString(str: String) {
        writeString(str, completion: nil)
    }
}
