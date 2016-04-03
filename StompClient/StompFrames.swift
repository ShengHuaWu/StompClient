//
//  StompFrames.swift
//  Surveillance
//
//  Created by ShengHua Wu on 3/23/16.
//  Copyright © 2016 nogle. All rights reserved.
//

import Foundation

// MARK: - Stomp Sending Frame
struct StompSendingFrame: CustomStringConvertible {
    
    // MARK: - Public Properties
    let command: StompSendingCommand
    var description: String {
        get {
            var string = command.name + lineFeed
            for (key, value) in command.headers {
                string += key + ":" + value + lineFeed
            }
            string += lineFeed + nullChar
            return string
        }
    }
    
    // MARK: - Private Properties
    private let lineFeed = "\u{0A}"
    private let nullChar = "\u{00}"
    
    // MARK: - Designated Initializer
    init(command: StompSendingCommand) {
        self.command = command
    }
    
}

// MARK: - Stomp Response Frame
struct StompResponseFrame {
    
    // MARK: - Response Types
    enum StompResponseType: String {
        case Open = "o"
        case HeartBeat = "h"
        case Array = "a"
        case Message = "m"
        case Close = "c"
    }
    
    // MARK: - Public Properties
    let type: StompResponseType
    let command: StompResponseCommand
    
    // MARK: - Designated Initializer
    init(message: String) {
        let firstChar = message.characters.first!
        self.type = StompResponseType(rawValue: String(firstChar))!
        
        switch self.type {
        case .Array:
            self.command = StompResponseCommand.parseMessage(message)
        default:
            self.command = .Unknown
            break
        }
    }
    
}
