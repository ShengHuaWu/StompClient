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
    
    // MARK: - Cases
    case Connect = "CONNECT"
    case Disconnect = "DISCONNECT"
    case Subscribe = "SUBSCRIBE"
    case Unsubscribe = "UNSUBSCRIBE"
    
    case Connected = "CONNECTED"
    case Message = "MESSAGE"
    case Error = "ERROR"
    
}

// MARK: - Headers
enum StompHeader: Hashable {
    
    // MARK: - Cases
    case AcceptVersion(version: String)
    case HeartBeat(value: String)
    case Destination(path: String)
    case DestinationId(id: String)
    case Custom(key: String, value: String)
    
    case Version(version: String)
    case Subscription(subId: String)
    case MessageId(id: String)
    case ContentLenght(length: String)
    case Message(body: String)
    
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
        case .ContentLenght:
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
        case .ContentLenght(let length):
            return length
        case .Message(let body):
            return body
        }
    }
    
    var hashValue: Int {
        return key.hashValue
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
}

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
    
    // MARK: - Private Properties
    private let lineFeed = "\u{0A}"
    private let nullChar = "\u{00}"
    private var type: StompResponseType?
    private let command: StompCommand
    private let headers: Set<StompHeader>
    
    // MARK: - Designated Initializer
    init(type: StompResponseType? = nil, command: StompCommand, headers: Set<StompHeader> = []) {
        self.type = type
        self.command = command
        self.headers = headers
    }
    
}
