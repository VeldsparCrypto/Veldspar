//
//  wallet_address.swift
//  Veldspar
//
//  Created by Adrian Herridge on 18/03/2019.
//

import Foundation

public class Wallet : Codable {
    
    public var wallets: [WalletAddress] = []
    public init() {}
    
}

public class WalletAddress : Codable {
    
    public var address: Data?
    public var name: String?
    public var alias: [String] = []
    public var seed: Data?
    public var height: Int?
    
    public var current_balance: Int?
    public var pending_balance: Int?
    public var incoming: [WalletTransfer] = []
    public var outgoing: [WalletTransfer] = []
    public var incoming_pending: [WalletTransfer] = []
    public var outgoing_pending: [WalletTransfer] = []
    
    public init() {}
    
}

public class WalletTransfer : Codable {
    
    public var ref: Data?
    public var date: UInt64?
    public var total: Int?
    public var destination: Data?
    public var source: Data?
    
    public init() {}
    
}
