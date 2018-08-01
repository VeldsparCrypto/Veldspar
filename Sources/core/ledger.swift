//
//  ledger.swift
//  SharkCore
//
//  Created by Adrian Herridge on 30/07/2018.
//

import Foundation

public enum LedgerOPType : Int {
    
    case Unset = 0
    case RegisterToken = 1
    case ChangeOwner = 2
    case ReWriteToken = 3
    
}

public class Ledger {

    public var transaction_id: String
    public var op: LedgerOPType
    public var date: UInt64
    public var transaction_group: String
    public var destination: String
    public var token: String
    public var spend_auth: String
    public var block: UInt64
    
    public init(op: LedgerOPType,token: String, ref: String, address: String, auth: String, block: UInt64) {
        self.transaction_id = UUID().uuidString.CryptoHash()
        self.op = op
        self.transaction_group = ref
        self.destination = address
        self.date = UInt64(Date().timeIntervalSince1970 * 1000)
        self.spend_auth = auth
        self.block = block
        self.token = token
    }
    
    public init(id: String, op: LedgerOPType, token: String, ref: String, address: String, date: UInt64, auth: String, block: UInt64) {
        self.transaction_id = id
        self.op = op
        self.transaction_group = ref
        self.destination = address
        self.date = date
        self.spend_auth = auth
        self.block = block
        self.token = token
    }
    
    public func checksum() -> String {
        return "\(transaction_id)\(op.rawValue)\(date)\(transaction_group)\(destination)\(spend_auth)\(block)".md5()
    }
    
}
