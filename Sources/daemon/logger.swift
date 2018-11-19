//    MIT License
//
//    Copyright (c) 2018 Veldspar Team
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.

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
    private var isDebug: Bool
    private var fileHandle: FileHandle
    
    public init(debug: Bool) {
        isDebug = debug
        if !FileManager.default.fileExists(atPath: "\(Config.CurrencyName).log") {
            try? "".write(toFile: "\(Config.CurrencyName).log", atomically: true, encoding: .ascii)
        }
        fileHandle = FileHandle(forWritingAtPath: "\(Config.CurrencyName).log")!
    }
    
    public func log( level: LogType, log: String) {
        
        if level == .Debug && isDebug == false {
            return
        }
        
        var outString = "[\(Date())] "
        let fileString = "[\(Date())] [\(level)] \(log)\n"
        
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
            _ = fileHandle.seekToEndOfFile()
            fileHandle.write(fileString.data(using: .ascii)!)
            
        }
        
    }
    
}
