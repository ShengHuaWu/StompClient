//
//  StompCommands.swift
//  Surveillance
//
//  Created by ShengHua Wu on 3/23/16.
//  Copyright © 2016 nogle. All rights reserved.
//

import Foundation

// MARK: - Stomp Sending Command
enum StompSendingCommand {
    
    // MARK: - Header Keys
    private static let headerAcceptVersion = "accept-version"
    private static let headerHeartBeat = "heart-beat"
    private static let headerDestination = "destination"
    private static let headerDestinationId = "id"
    private static let headerParametersKey = "key"
    
    // MARK: - Cases
    case Connect(acceptVersion: String, heartBeat: String)
    case Disconnect
    case Subscribe(destination: String, destinationId: String, parameters: ParametersConvertible?)
    case Unsubscribe(destination: String)
    
    // MARK: - Public Properties
    var name: String {
        switch self {
        case .Connect:
            return "CONNECT"
        case .Disconnect:
            return "DISCONNECT"
        case .Subscribe:
            return "SUBSCRIBE"
        case .Unsubscribe:
            return "UNSUBSCRIBE"
        }
    }
    
    var headers: [String : String] {
        switch self {
        case .Connect(let acceptVersion, let heartBeat):
            return [StompSendingCommand.headerAcceptVersion : acceptVersion, StompSendingCommand.headerHeartBeat : heartBeat]
        case .Disconnect:
            return [:]
        case .Subscribe(let destination, let destinationId, let parameters):
            if let parameters = parameters {
                return [StompSendingCommand.headerDestination : destination, StompSendingCommand.headerDestinationId : destinationId, StompSendingCommand.headerParametersKey : parameters.description]
            } else {
                return [StompSendingCommand.headerDestination : destination, StompSendingCommand.headerDestinationId : destinationId]
            }
        case .Unsubscribe(let destination):
            return [StompSendingCommand.headerDestination : destination]
        }
    }
    
}

// MARK: - Stomp Response Command
enum StompResponseCommand {
    
    // MARK: - Header Keys
    private static let headerVersion = "version"
    private static let headerHeartBeat = "heart-beat"
    private static let headerDestination = "destination"
    private static let headerSubscription = "subscription"
    private static let headerMessageId = "message-id"
    private static let headerContentLenght = "content-length"
    private static let headerMessage = "message"
    
    // MARK: - Cases
    case Connected(version: String, heartBeat: String)
    case Message(destination: String, subscription: String, messageId: String, contentLength: String, body: String)
    case Error(message: String, contentLength: String)
    case Unknown
    
    // MARK: - Public Methods
    static func parseMessage(message: String) -> StompResponseCommand {
        let jsonString = String(message.characters.dropFirst())
        let jsonData = jsonString.dataUsingEncoding(NSUTF8StringEncoding)!
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(jsonData, options: .AllowFragments) as! [String]
            let components = json.first!.componentsSeparatedByString("\n")
            let command = components.first!
            var headers = [String : String]()
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
                        headers[parts.first!] = parts.last
                    }
                }
            }
            return generateCommand(command, headers: headers, body: body)
        } catch let error as NSError {
            return .Error(message: error.localizedDescription, contentLength: "")
        }
    }
    
    // MARK: - Private Methods
    static private func generateCommand(command: String, headers: [String : String], body: String) -> StompResponseCommand {
        switch command {
        case "CONNECTED":
            return .Connected(version: headers[headerVersion]!, heartBeat: headers[headerHeartBeat]!)
        case "MESSAGE":
            return .Message(destination: headers[headerDestination]!, subscription: headers[headerSubscription]!, messageId: headers[headerMessageId]!, contentLength: headers[headerContentLenght]!, body: body)
        case "ERROR":
            return .Error(message: headers[headerMessage]!, contentLength: headers[headerContentLenght]!)
        default:
            return .Unknown
        }
    }
    
}
