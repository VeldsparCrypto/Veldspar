//
//  block_sync.swift
//  veldspard
//
//  Created by Adrian Herridge on 08/11/2018.
//

import Foundation
import VeldsparCore

class BlockSync {
    
    class func Loop() {
        
        while true {
            
            if blockchain.height() < Comms.requestHeight() ?? -1 {
                
            }
            
        }
        
    }
    
}
