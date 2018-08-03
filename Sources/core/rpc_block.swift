//
//  rpc_block.swift
//  VeldsparCore
//
//  Created by Adrian Herridge on 03/08/2018.
//

import Foundation

public class RPC_Block : Codable {
    
    public var height: UInt32?
    public var seed: String?
    public var hash: String?
    
    public var transactions: [RPC_Ledger] = []
    
    public init() {}
    
}

public class RPC_Ledger : Codable {
    
    public var transaction_id: String?
    public var op: Int?
    public var date: UInt64?
    public var transaction_group: String?
    public var destination: String?
    public var token: String?
    public var spend_auth: String?
    public var block: UInt32?
    
    public init() {}
    
}
