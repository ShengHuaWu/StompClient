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
    
    case connect = "CONNECT"
    case disconnect = "DISCONNECT"
    case subscribe = "SUBSCRIBE"
    case unsubscribe = "UNSUBSCRIBE"
    
    case connected = "CONNECTED"
    case message = "MESSAGE"
    case error = "ERROR"
    
    // MARK: - Public Methods
    static func parseText(_ text: String) throws -> StompCommand {
        guard let command = StompCommand(rawValue: text) else {
            throw NSError(domain: "com.shenghuawu.error", code: 1002, userInfo: [NSLocalizedDescriptionKey : "Received command is undefined."])
        }
        return command
    }
    
}

// MARK: - Headers
enum StompHeader: Hashable {
    
    case acceptVersion(version: String)
    case heartBeat(value: String)
    case destination(path: String)
    case destinationId(id: String)
    case custom(key: String, value: String)
    
    case version(version: String)
    case subscription(subId: String)
    case messageId(id: String)
    case contentLength(length: String)
    case message(message: String)
    case userName(name: String)
    case contentType(type: String)
    
    // MARK: - Public Properties
    var key: String {
        switch self {
        case .acceptVersion:
            return "accept-version"
        case .heartBeat:
            return "heart-beat"
        case .destination:
            return "destination"
        case .destinationId:
            return "id"
        case .custom(let key, _):
            return key
        case .version:
            return "version"
        case .subscription:
            return "subscription"
        case .messageId:
            return "message-id"
        case .contentLength:
            return "content-length"
        case .message:
            return "message"
        case .userName:
            return "user-name"
        case .contentType:
            return "content-type"
        }
    }
    
    var value: String {
        switch self {
        case .acceptVersion(let version):
            return version
        case .heartBeat(let value):
            return value
        case .destination(let path):
            return path
        case .destinationId(let id):
            return id
        case .custom(_, let value):
            return value
        case .version(let version):
            return version
        case .subscription(let subId):
            return subId
        case .messageId(let id):
            return id
        case .contentLength(let length):
            return length
        case .message(let body):
            return body
        case .userName(let name):
            return name
        case .contentType(let type):
            return type
        }
    }
    
    var isMessage: Bool {
        switch self {
        case .message:
            return true
        default:
            return false
        }
    }
    
    var isDestination: Bool {
        switch self {
        case .destination:
            return true
        default:
            return false
        }
    }
    
    var hashValue: Int {
        return key.hashValue
    }
    
    // MARK: - Public Methods
    static func parseKeyValuePair(_ key: String, value: String) -> StompHeader {
        switch key {
        case "version":
            return .version(version: value)
        case "subscription":
            return .subscription(subId: value)
        case "message-id":
            return .messageId(id: value)
        case "content-length":
            return .contentLength(length: value)
        case "message":
            return .message(message: value)
        case "destination":
            return .destination(path: value)
        case "heart-beat":
            return .heartBeat(value: value)
        case "user-name":
            return .userName(name: value)
        case "content-type":
            return .contentType(type: value)
        default:
            return .custom(key: key, value: value)
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
    static func parseCharacter(_ char: Character) throws -> StompResponseType {
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
    fileprivate let lineFeed = "\n"
    fileprivate let nullChar = "\0"
    fileprivate(set) var command: StompCommand
    fileprivate(set) var headers: Set<StompHeader>
    fileprivate(set) var body: String?
    
    // MARK: - Designated Initializer
    init(command: StompCommand, headers: Set<StompHeader> = [], body: String? = nil) {
        self.command = command
        self.headers = headers
        self.body = body
    }
    
    // MARK: - Public Methods
    static func parseText(_ text: String) throws -> StompFrame {
        guard let components = try text.parseJSONString() , !components.isEmpty else {
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
                    body = body.replacingOccurrences(of: "\0", with: "")
                }
            } else {
                if component == "" {
                    isBody = true
                } else {
                    let parts = component.components(separatedBy: ":")
                    guard let key = parts.first, let value = parts.last else {
                        continue
                    }
                    let header = StompHeader.parseKeyValuePair(key, value: value)
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
        return try data(using: String.Encoding.utf8).flatMap { data -> [String]? in
            return try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String]
        }.flatMap { stringArray -> [String]? in
            return stringArray.first?.components(separatedBy: "\n")
        }
    }
    
}
