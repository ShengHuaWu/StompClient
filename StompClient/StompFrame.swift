//
//  StompFrame.swift
//  StompClient
//
//  Created by ShengHua Wu on 4/13/16.
//  Copyright © 2016 shenghuawu. All rights reserved.
//

import Foundation

// MARK: - Commands
enum StompCommand: String {
    
    case Connect = "CONNECT"
    case Disconnect = "DISCONNECT"
    case Subscribe = "SUBSCRIBE"
    case Unsubscribe = "UNSUBSCRIBE"
    
    case Connected = "CONNECTED"
    case Message = "MESSAGE"
    case Error = "ERROR"
    
    // MARK: - Public Methods
    static func parseText(text: String) throws -> StompCommand {
        guard let command = StompCommand(rawValue: text) else {
            throw NSError(domain: "com.shenghuawu.error", code: 1002, userInfo: [NSLocalizedDescriptionKey : "Received command is undefined."])
        }
        return command
    }
    
}

// MARK: - Headers
enum StompHeader: Hashable {
    
    case AcceptVersion(version: String)
    case HeartBeat(value: String)
    case Destination(path: String)
    case DestinationId(id: String)
    case Custom(key: String, value: String)
    
    case Version(version: String)
    case Subscription(subId: String)
    case MessageId(id: String)
    case ContentLength(length: String)
    case Message(message: String)
    
    // MARK: - Public Properties
    var key: String {
        switch self {
        case .AcceptVersion:
            return "accept-version"
        case .HeartBeat:
            return "heart-beat"
        case .Destination:
            return "destination"
        case .DestinationId:
            return "id"
        case .Custom(let key, _):
            return key
        case .Version:
            return "version"
        case .Subscription:
            return "subscription"
        case .MessageId:
            return "message-id"
        case .ContentLength:
            return "content-length"
        case .Message:
            return "message"
        }
    }
    
    var value: String {
        switch self {
        case .AcceptVersion(let version):
            return version
        case .HeartBeat(let value):
            return value
        case .Destination(let path):
            return path
        case .DestinationId(let id):
            return id
        case .Custom(_, let value):
            return value
        case .Version(let version):
            return version
        case .Subscription(let subId):
            return subId
        case .MessageId(let id):
            return id
        case .ContentLength(let length):
            return length
        case .Message(let body):
            return body
        }
    }
    
    var isMessage: Bool {
        switch self {
        case .Message:
            return true
        default:
            return false
        }
    }
    
    var isDestination: Bool {
        switch self {
        case .Destination:
            return true
        default:
            return false
        }
    }
    
    var hashValue: Int {
        return key.hashValue
    }
    
    // MARK: - Public Methods
    static func parseKeyValuePair(key: String, value: String) throws -> StompHeader {
        switch key {
        case "version":
            return .Version(version: value)
        case "subscription":
            return .Subscription(subId: value)
        case "message-id":
            return .MessageId(id: value)
        case "content-length":
            return .ContentLength(length: value)
        case "message":
            return .Message(message: value)
        case "destination":
            return .Destination(path: value)
        case "heart-beat":
            return .HeartBeat(value: value)
        default:
            throw NSError(domain: "com.shenghuawu.error", code: 1000, userInfo: [NSLocalizedDescriptionKey : "Received header is undefined."])
        }
    }
    
}

// MARK: - Equatable for Stomp Header
func ==(lhs: StompHeader, rhs: StompHeader) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

// MARK: - Response Types
enum StompResponseType: String {
    
    case Open = "o"
    case HeartBeat = "h"
    case Array = "a"
    case Message = "m"
    case Close = "c"
    
    // MARK: - Public Methods
    static func parseCharacter(char: Character) throws -> StompResponseType {
        guard let type = StompResponseType(rawValue: String(char)) else {
            throw NSError(domain: "com.shenghuawu.error", code: 1001, userInfo: [NSLocalizedDescriptionKey : "Received type is undefined."])
        }
        return type
    }
    
}

// MARK: - Frame
struct StompFrame: CustomStringConvertible {
    
    // MARK: - Public Properties
    var description: String {
        var string = command.rawValue + lineFeed
        for header in headers {
            string += header.key + ":" + header.value + lineFeed
        }
        string += lineFeed + nullChar
        return string
    }
    
    var message: String {
        if let header = headers.filter({ $0.isMessage }).first {
            return header.value
        } else {
            return ""
        }
    }
    
    var destination: String {
        if let header = headers.filter({ $0.isDestination }).first {
            return header.value
        } else {
            return ""
        }
    }
    
    // MARK: - Private Properties
    private let lineFeed = "\n"
    private let nullChar = "\0"
    private(set) var command: StompCommand
    private(set) var headers: Set<StompHeader>
    private(set) var body: String?
    
    // MARK: - Designated Initializer
    init(command: StompCommand, headers: Set<StompHeader> = [], body: String? = nil) {
        self.command = command
        self.headers = headers
        self.body = body
    }
    
    // MARK: - Public Methods
    static func parseText(text: String) throws -> StompFrame {
        guard let components = try text.parseJSONString() where !components.isEmpty else {
            throw NSError(domain: "com.shenghuawu.error", code: 1002, userInfo: [NSLocalizedDescriptionKey : "Received frame is empty."])
        }
        let command = try StompCommand.parseText(components.first!)
        
        var headers: Set<StompHeader> = []
        var body = ""
        var isBody = false
        for index in 1 ..< components.count {
            let component = components[index]
            if isBody {
                body += component
                if body.hasSuffix("\0") {
                    body = body.stringByReplacingOccurrencesOfString("\0", withString: "")
                }
            } else {
                if component == "" {
                    isBody = true
                } else {
                    let parts = component.componentsSeparatedByString(":")
                    guard let key = parts.first, let value = parts.last else {
                        continue
                    }
                    let header = try StompHeader.parseKeyValuePair(key, value: value)
                    headers.insert(header)
                }
            }
        }
        return StompFrame(command: command, headers: headers, body: body)
    }
    
}

// MARK: - Extensions
extension String {
    
    func parseJSONString() throws -> [String]? {
        return try dataUsingEncoding(NSUTF8StringEncoding).flatMap { data -> [String]? in
            return try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as? [String]
        }.flatMap { stringArray -> [String]? in
            return stringArray.first?.componentsSeparatedByString("\n")
        }
    }
    
}
