//
//  PendingSyncObject.swift
//  VeldsparCore
//
//  Created by Adrian Herridge on 08/11/2018.
//

import Foundation

public struct PendingSyncObject : Codable {
    
    public var min_height: Int?
    public var pending_ledgers: [Ledger] = []
    public init () {}
    
}
