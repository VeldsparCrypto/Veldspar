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

class BroadcastSwarm {
    
    static var lock = Mutex()
    static var outstanding: Int = 0
    static var threshhold = 10
    
    init() {
        
        BroadcastSwarm.processNext()
        
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
    
    class func processNext() {
        
        lock.mutex {
            
            if outstanding <= threshhold {
                Execute.background {
                    
                    let d = tempManager.popIntOutBroadcast()
                    if d != nil {
                        
                        logger.log(level: .Info, log: "Sent broadcast intra-node-transfer to swarm. Hash of \(d!.sha224().toHexString())")
                        
                        // get everywhere this needs to be sent
                        let nodes = blockchain.nodesAll()
                        lock.mutex {
                            outstanding += nodes.count
                        }
                        
                        for n in nodes {
                            
                            self.HTTPPostJSON(url: "http://\(n)/int", data: d!) { (err, result) in
                                
                                // now decrement the outstanding
                                lock.mutex {
                                    outstanding -= 1
                                }
                                
                            }
                            
                        }
                        
                        Execute.background {
                            BroadcastSwarm.processNext()
                        }
                        
                    } else {
                        
                        // nothing to do for this node, so sleep until there is some work
                        Execute.backgroundAfter(after: 1.0, {
                            BroadcastSwarm.processNext()
                        })
                        
                    }
                    
                }
            }
        }

    }
    
}
