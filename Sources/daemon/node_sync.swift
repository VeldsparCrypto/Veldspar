//
//  node_sync.swift
//  veldspard
//
//  Created by Adrian Herridge on 13/11/2018.
//

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
            
            // clean up stale nodes
            blockchain.purgeStaleNodes()
            
            Thread.sleep(forTimeInterval: 60)
            
        }
        
    }
    
}
