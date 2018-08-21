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

public enum LogType: String {
    case Info =     "INFO"
    case Debug =    "DEBUG"
    case Warning =  "WARNING"
    case Error =    "ERROR"
    case SlowQuery = "SLOW"
}

public class Log {
    
    var level: LogType?
    var entry: String?
    var token: String?
    var source: String?
    var duration: Int = 0
    
}

public class Logger {
    
    private var lock: Mutex = Mutex()
    private var pending: [Log] = []
    
    init() {
        Execute.background {
            while true {
                self.lock.mutex {
                    _ = log_db.execute(sql: "BEGIN TRANSACTION;", params: [])
                    
                    // type TEXT, entry TEXT, timestamp TEXT, request TEXT, token TEXT, source TEXT
                    for l in self.pending {
                        _ = log_db.execute(sql: "INSERT INTO log (type, entry, timestamp, source, token, duration) VALUES (?,?,?,?,?,?)", params: [
                            
                            l.level!.rawValue,
                            l.entry!,
                            "\(Date())",
                            l.source ?? NSNull(),
                            l.token ?? NSNull(),
                            l.duration
                            
                            ])
                    }
                    self.pending.removeAll()
                    
                    _ = log_db.execute(sql: "COMMIT TRANSACTION;", params: [])
                }
                sleep(10)
            }
        }
    }
    
    public func log( level: LogType, log: String, token: String?, source: String?, duration: Int) {
        
        let l = Log()
        l.level = level
        l.entry = log
        l.token = token
        l.source = source
        l.duration = duration
        
        lock.mutex {
            pending.append(l)
        }
        
    }
    
    public func query(q: String?, token: String?, limit: Int, duration: Int?) {
        
        lock.mutex {
            
            var results: Result?
            if q != nil {
                results = log_db.query(sql: "SELECT * FROM log WHERE lower(entry) LIKE ? LIMIT ?", params: ["%\(q!.lowercased())%", limit])
            } else if token != nil {
                results = log_db.query(sql: "SELECT * FROM log WHERE token = ? LIMIT ?", params: [token!, limit])
            } else if duration != nil {
                results = log_db.query(sql: "SELECT * FROM log WHERE duration >= ? LIMIT ?", params: [duration!, limit])
            } else {
                results = log_db.query(sql: "SELECT * FROM log WHERE id IN (SELECT id FROM log ORDER BY id DESC LIMIT ?) ORDER BY id ASC LIMIT ?", params: [limit,limit])
            }
            
            if results != nil && results!.results.count > 0 {
                print("")
                print("Date|Entry|Token|Duration")
                // type TEXT, entry TEXT, timestamp TEXT, request TEXT, token TEXT, source TEXT, duration INTEGER);"
                for r in results!.results {
                    print("[\(r["type"]!.asString() ?? "")] | \(r["entry"]!.asString() ?? "") | \(r["token"]!.asString() ?? "") | \(r["source"]!.asString() ?? "") | \(r["duration"]!.asInt() ?? 0) ms")
                }
                print("")
            }
            
        }
        
    }
    
}
