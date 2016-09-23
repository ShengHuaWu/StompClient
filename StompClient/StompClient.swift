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
    
    func stompClientDidConnected(_ client: StompClient)
    func stompClient(_ client: StompClient, didErrorOccurred error: NSError)
    func stompClient(_ client: StompClient, didReceivedData data: Data, fromDestination destination: String)
    
}

open class StompClient: NSObject {
    
    // MARK: - Public Properties
    open weak var delegate: StompClientDelegate?
    open var isConnected: Bool {
        return socket.isConnected
    }

    // MARK: - Private Properties
    fileprivate var socket: WebSocketProtocol
    
    // MARK: - Designated Initializer
    public init(socket: WebSocketProtocol) {
        self.socket = socket
        
        super.init()
        
        self.socket.delegate = self
    }
    
    // MARK: - Convenience Initializer
    public convenience init(url: URL) {
        let socket = WebSocket(url: url)
        self.init(socket: socket)
    }
    
    // MARK: - Public Methods
    open func setValue(_ value: String, forHeaderField field: String) {
        socket.headers[field] = value
    }
    
    open func connect() {
        socket.connect()
    }
    
    open func disconnect() {
        sendDisconnect()
        socket.disconnect(0.0)
    }
    
    open func subscribe(_ destination: String, parameters: [String : String]? = nil) -> String {
        let id = "sub-" + Int(arc4random_uniform(1000)).description
        var headers: Set<StompHeader> = [.destinationId(id: id), .destination(path: destination)]
        if let params = parameters , !params.isEmpty {
            for (key, value) in params {
                headers.insert(.custom(key: key, value: value))
            }
        }
        let frame = StompFrame(command: .Subscribe, headers: headers)
        sendFrame(frame)
        
        return id
    }

    open func unsubscribe(_ destination: String, destinationId: String) {
        let headers: Set<StompHeader> = [.destinationId(id: destinationId), .destination(path: destination)]
        let frame = StompFrame(command: .Unsubscribe, headers: headers)
        sendFrame(frame)
    }
    
    // MARK: - Private Methods
    fileprivate func sendConnect() {
        let headers: Set<StompHeader> = [.acceptVersion(version: "1.1"), .heartBeat(value: "10000,10000")]
        let frame = StompFrame(command: .Connect, headers: headers)
        sendFrame(frame)
    }
    
    fileprivate func sendDisconnect() {
        let frame = StompFrame(command: .Disconnect)
        sendFrame(frame)
    }
    
    fileprivate func sendFrame(_ frame: StompFrame) {
        let data = try! JSONSerialization.data(withJSONObject: [frame.description], options: JSONSerialization.WritingOptions(rawValue: 0))
        let string = String(data: data, encoding: String.Encoding.utf8)!
        // Because STOMP is a message convey protocol, only this delegate method
        // will be called, and we MUST use -writeString method to pass messages.
        socket.writeString(string)
    }
    
}

// MARK: - Websocket Delegate
extension StompClient: WebSocketDelegate {
    
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
        let firstCharacter = mutableText.remove(at: mutableText.startIndex)
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
                guard let data = frame.body?.data(using: String.Encoding.utf8) else {
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
    
    public func websocketDidReceiveData(socket: WebSocket, data: Data) {
        // This delegate will NOT be called, since STOMP is a message convey protocol.
    }
    
}

// MARK: - Extensions
extension URL {
    
    func appendServerIdAndSessionId() -> URL {
        let serverId = Int(arc4random_uniform(1000)).description
        let sessionId = String.randomAlphaNumericString(8)
        var path = (serverId as NSString).appendingPathComponent(sessionId)
        path = (path as NSString).appendingPathComponent("websocket")
        
        return self.appendingPathComponent(path)
    }
    
}

extension String {
    
    static func randomAlphaNumericString(_ length: Int) -> String {
        let allowedChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let allowedCharsCount = UInt32(allowedChars.characters.count)
        var randomString = ""
        
        for _ in (0 ..< length) {
            let randomNum = Int(arc4random_uniform(allowedCharsCount))
            let newCharacter = allowedChars[allowedChars.characters.index(allowedChars.startIndex, offsetBy: randomNum)]
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
    func disconnect(_ forceTimeout: TimeInterval?)
    func writeString(_ str: String)
    
}

extension WebSocket: WebSocketProtocol {
    public func disconnect(_ forceTimeout: TimeInterval?) {
        disconnect(forceTimeout: forceTimeout)
    }

    
    public func writeString(_ str: String) {
        write(string: str, completion: nil)
    }
}
