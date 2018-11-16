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
        
        while true {
            
            for s in Config.SeedNodes {
                
                let d = Comms.basicRequest(address: s, method: "nodes", parameters: [:])
                
            }
            
        }
        
    }
    
}
