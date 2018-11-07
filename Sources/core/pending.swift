//
//  pending.swift
//  VeldsparCore
//
//  Created by Adrian Herridge on 06/11/2018.
//

import Foundation

public struct Pending : Codable {
    
    var transactions : [Ledger] = []
    init() {}
    
}
