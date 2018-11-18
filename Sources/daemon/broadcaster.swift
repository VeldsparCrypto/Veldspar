//
//  broadcaster.swift
//  veldspard
//
//  Created by Adrian Herridge on 13/11/2018.
//

import Foundation
import VeldsparCore

class Broadcaster {
    
    var lock = Mutex()
    var isBroadcasting = false
    private var outstandingLedgers: [Ledger] = []
    
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
        
        Execute.background {
            
            while true {
                
                // grab the nodes
                let nodes = blockchain.nodes()
                let newBroadcast = Ledgers()
                newBroadcast.broadcastId = UUID().uuidString.lowercased().replacingOccurrences(of: "-", with: "").sha224()
                self.lock.mutex {
                    let ledgers = self.outstandingLedgers.prefix(100000)
                    self.outstandingLedgers.removeFirst(ledgers.count)
                    newBroadcast.transactions.append(contentsOf: ledgers)
                    newBroadcast.source_nodeId = thisNode.nodeId
                    newBroadcast.visitedNodes.append(thisNode.nodeId!)
                }
                
                if newBroadcast.transactions.count > 0 {
                    
                    // now we can throw this broadcast to all the nodes on the network which can be reached.
                    do {
                        
                        let jsonData = try JSONEncoder().encode(newBroadcast)
                        
                        if !settings.isSeedNode {
                            // send this to the seed nodes first
                            var seedNodes = Config.SeedNodes
                            if isTestNet {
                                seedNodes = Config.TestNetNodes
                            }
                            for n in seedNodes {
                                Execute.background {
                                    self.HTTPPostJSON(url: "http://\(n)/int", data: jsonData) { (err, result) in
                                        if(err != nil){
                                            return
                                        }
                                    }
                                }
                            }
                        }
                        
                        // now distribute to the wider community.
                        
                        for n in nodes {
                            
                            Execute.background {
                                self.HTTPPostJSON(url: "http://\(n.address!)/int", data: jsonData) { (err, result) in
                                    if(err != nil){
                                        return
                                    }
                                }
                            }
                            
                        }
                        
                        
                    } catch {
                        
                    }
                    
                }

                Thread.sleep(forTimeInterval: 1)
                
            }
            
        }
        
    }
    
    func  add(_ ledgers: [Ledger]) {
        
        lock.mutex {
            outstandingLedgers.append(contentsOf: ledgers)
        }
        
    }
    
}