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

typealias BroadcastFailure = (address: String, id: String, data: Data, date: Int, failCount: Int)

class BroadcastFailed {
    
    static var lock = Mutex()
    static var failed: [BroadcastFailure] = []
    
    init() {
        
        URLSession.shared.configuration.timeoutIntervalForRequest = 600
        BroadcastFailed.processNext()
        
    }
    
    //Method just to execute request, assuming the response type is string (and not file)
    class func HTTPsendRequest(request: URLRequest,
                               callback: @escaping (Error?, String?) -> Void) {
        let task = URLSession.shared.dataTask(with: request) { (data, res, err) in
            if (err != nil) {
                callback(err,nil)
            } else {
                callback(nil, String(data: data!, encoding: String.Encoding.utf8))
            }
        }
        task.resume()
    }
    
    // post JSON
    class func HTTPPostJSON(url: String,  data: Data,
                            callback: @escaping (Error?, String?) -> Void) {
        
        var request = URLRequest(url: URL(string: url)!)
        
        request.httpMethod = "POST"
        request.addValue("application/json",forHTTPHeaderField: "Content-Type")
        request.addValue("application/json",forHTTPHeaderField: "Accept")
        request.httpBody = data
        HTTPsendRequest(request: request, callback: callback)
        
    }
    
    class func enqeueBroadcast(failure: BroadcastFailure) {
        lock.mutex {
            failed.append(failure)
        }
    }
    
    class func processNext() {
        
        lock.mutex {
            
            Execute.background {
                
                if failed.count > 0 {
                    
                    let fCopy = Array<BroadcastFailure>(self.failed)
                    self.failed = []
                    
                    for failure in fCopy {
                        
                        var f = failure
                        
                        // try to re-send every single failure until failure count has reached max
                        if f.failCount < 10 {
                            
                            logger.log(level: .Debug, log: "Sending failed intra-node-transfer (\(f.id)) to Seed Node \(f.address)")
                            self.HTTPPostJSON(url: "http://\(f.address)/int?id=\(f.id)", data: f.data) { (err, result) in
                                if err != nil {
                                    f.failCount = f.failCount + 1
                                    lock.mutex {
                                        self.failed.append(f)
                                    }
                                } else {
                                    
                                }
                            }
                        }
                    }
                }
                
                // queue up the next thread to process the failures
                Execute.backgroundAfter(after: 60.0, {
                    self.processNext()
                })
                
            }
        }
    }
}

