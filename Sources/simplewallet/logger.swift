//
//  logger.swift
//  simplewallet
//
//  Created by Adrian Herridge on 17/12/2018.
//

import Foundation
import VeldsparCore
import SWSQLite
import Rainbow

public enum LogType: String {
    case Info =     "INFO"
    case Debug =    "DEBUG"
    case Warning =  "WARNING"
    case Error =    "ERROR"
    case SlowQuery = "SLOW"
}

public class Logger {
    
    private var lock: Mutex = Mutex()
    
    public func log( level: LogType, log: String) {
        
        var outString = "[\(Date())] "
        
        switch level {
        case .Debug:
            outString += "[\(level)] \(log)".blue
        case .Info:
            outString += "[\(level)] \(log)"
        case .Error:
            outString += "[\(level)] \(log)".red
        case .Warning:
            outString += "[\(level)] \(log)".yellow
        default:
            outString += "[\(level)] \(log)"
        }
        
        lock.mutex {
            
            // write out to the logfile and print out to the screen.
            print(outString)
            
        }
        
    }
    
}
