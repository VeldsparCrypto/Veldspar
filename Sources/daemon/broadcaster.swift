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
    
    func broadcast() {
        
        Execute.background {
            
            while true {
                
                Thread.sleep(forTimeInterval: 1)
                
            }
            
        }
        
    }
    
}
