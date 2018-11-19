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

class NodeSync {
    
    class func SyncNodes() {
        
        var nodes = Config.SeedNodes
        if isTestNet {
            nodes = Config.TestNetNodes
        }
        
        while true {
            
            for s in nodes {
                
                let d = comms.basicRequest(address: s, method: "nodes", parameters: [:])
                if d != nil {
                    do {
                        
                        let currentNodes = try JSONDecoder().decode(NodeListResponse.self, from: d!)
                        blockchain.putNodes(currentNodes.nodes)
                        
                    } catch {}
                }
            }
            
            // now update our local reachability records
            for n in blockchain.nodes() {
                
                if comms.basicRequest(address: n.address!, method:"timestamp" , parameters: [:]) != nil {
                    n.lastcomm = UInt64(Date().timeIntervalSince1970 * 1000)
                    blockchain.putNode(n)
                }
                
            }
            
            // clean up stale nodes
            blockchain.purgeStaleNodes()
            
            Thread.sleep(forTimeInterval: 60)
            
        }
        
    }
    
}
