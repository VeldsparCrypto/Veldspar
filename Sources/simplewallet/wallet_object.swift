//
//  wallet_object.swift
//  simplewallet
//
//  Created by Adrian Herridge on 04/08/2018.
//

import Foundation
import VeldsparCore
import CryptoSwift

class Wallet : Codable {
    
    var seed: String?
    var address: String?
    var height: UInt32?
    var tokens: [String:WalletToken] = [:]
    var transactions: [WalletTransaction] = []
    var name: String?
    
    func balance() -> Float {
        
        var balance = Float(0.0)
        
        for t in tokens.values {
            balance += (Float(t.value!) / Float(Config.DenominationDivider))
        }
        
        return balance
        
    }
    
}

class WalletToken : Codable {
    
    var token: String?
    var value: UInt32?
    
}

class WalletTransaction : Codable {
    
    var value: UInt32 = 0
    var destination: String?
    var date: UInt64?
    var ref: String?
    
}
