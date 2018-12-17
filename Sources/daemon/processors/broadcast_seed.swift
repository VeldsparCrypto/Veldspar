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

class BroadcastSeed {
    
    init() {
        
        var seedNodes = Config.SeedNodes
        if isTestNet {
            seedNodes = Config.TestNetNodes
        }
        for n in seedNodes {
            BroadcastSeed.processNext(n)
        }
        
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
    
    class func processNext(_ n: String) {
        
        Execute.background {
            
            let d = tempManager.popIntOutSeed(n)
            if d != nil && d?.data != nil {
                
                self.HTTPPostJSON(url: "http://\(n)/int", data: d!.data) { (err, result) in
                    if(err != nil) {
                        
                        logger.log(level: .Info, log: "Unable to contact seed node '\(n)', caching update until later.")
                        
                        // there was an error, so we need to restore the file back to disk again after waiting for a bit, otherwise the cycle will continue
                        tempManager.putBroadcastOutSeed(d!.data, seed: n, named: d!.fileId)
                        
                        Execute.backgroundAfter(after: 5.0, {
                            processNext(n)
                        })
                        
                    } else {
                                                
                        logger.log(level: .Info, log: "Sent delayed intra-node-transfer to seed node '\(n)' hash of \(d!.data.sha224().toHexString())")
                        Execute.background {
                            processNext(n)
                        }
                        
                    }
                }
            } else {
                // nothing to do for this node, so sleep until there is some work
                Execute.backgroundAfter(after: 1.0, {
                    processNext(n)
                })
            }
            
        }
        
    }
    
}
