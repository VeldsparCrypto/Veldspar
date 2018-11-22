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

class Broadcaster {
    
    var isBroadcasting = false
    
    //Method just to execute request, assuming the response type is string (and not file)
    func HTTPsendRequest(request: URLRequest,
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
    func HTTPPostJSON(url: String,  data: Data,
                      callback: @escaping (Error?, String?) -> Void) {
        
        var request = URLRequest(url: URL(string: url)!)
        
        request.httpMethod = "POST"
        request.addValue("application/json",forHTTPHeaderField: "Content-Type")
        request.addValue("application/json",forHTTPHeaderField: "Accept")
        request.httpBody = data
        HTTPsendRequest(request: request, callback: callback)
    }
    
    func broadcast() {
        
        var seedNodes = Config.SeedNodes
        if isTestNet {
            seedNodes = Config.TestNetNodes
        }
        for n in seedNodes {
            
            // create a thread for every seed node transfer
            Execute.background {
                while true {
                    let d = tempManager.popIntOutSeed(n)
                    if d != nil && d?.data != nil {
                        self.HTTPPostJSON(url: "http://\(n)/int", data: d!.data) { (err, result) in
                            if(err != nil) {
                                // there was an error, so we need to restore the file back to disk again after waiting for a bit, otherwise the cycle will continue
                                Thread.sleep(forTimeInterval: 5)
                                tempManager.putBroadcastOutSeed(d!.data, seed: n, named: d!.fileId)
                                
                            } else {
                                logger.log(level: .Info, log: "Sent delayed intra-node-transfer to seed node '\(n)' hash of \(d!.data.sha224().toHexString())")
                            }
                        }
                    } else {
                        // nothing to do for this node, so sleep until there is some work
                        Thread.sleep(forTimeInterval: 1)
                    }
                }
            }
            
        }
        
        Execute.background {
            
            // node transfers
            while true {

                // grab the nodes
                let nodes = blockchain.nodes()
                
                for n in nodes {
                    
                    let d = tempManager.popIntOutBroadcast()
                    if d != nil {
                        
                        Execute.background {
                            self.HTTPPostJSON(url: "http://\(n.address!)/int", data: d!) { (err, result) in
                                if(err != nil){
                                    return
                                }
                            }
                        }
                        
                    }

                }
                
                Thread.sleep(forTimeInterval: 1)
                
            }
            
        }
        
    }
    
    func  add(_ ledgers: [Ledger], atomic: Bool) {
        
        let l = Ledgers()
        l.atomic = atomic
        l.broadcastId = UUID().uuidString.lowercased()
        l.source_nodeId = thisNode.nodeId
        l.visitedNodes = []
        l.transactions = []
        l.transactions.append(contentsOf: ledgers)
        
        // throw this transaction into the temp cache manager now on background thread
        Execute.background {
            
            let d = try? JSONEncoder().encode(l)
            if d != nil {
                tempManager.putBroadcastOut(d!)
                var seedNodes = Config.SeedNodes
                if isTestNet {
                    seedNodes = Config.TestNetNodes
                }
                for n in seedNodes {
                    tempManager.putBroadcastOutSeed(d!, seed: n)
                }
            }
            
        }
        
    }
    
}
