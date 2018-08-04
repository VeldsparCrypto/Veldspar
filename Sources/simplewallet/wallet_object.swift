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
    
    class func read(filename: String, password: String) -> Wallet? {
        
        // read the file in
        do {
            
            let encryptedData = try Data(contentsOf: URL(fileURLWithPath: filename))
            let aes = try AES(key: String(password.sha224().prefix(16)), iv: String(password.sha224().sha224().prefix(16))) // aes128
            let decryptedData = try aes.decrypt(Array(encryptedData))
            let walletObject = try? JSONDecoder().decode(self, from: Data(bytes: decryptedData))
            
            if walletObject != nil {
                return walletObject
            }
            
        } catch  {
            
        }
        
        return nil
        
    }
    
    func write(filename: String, password: String) {
        
        do {
            let encodedData = try? JSONEncoder().encode(self)
            if encodedData != nil {
                let aes = try AES(key: String(password.sha224().prefix(16)), iv: String(password.sha224().sha224().prefix(16))) // aes128
                let ciphertext = try Data(bytes: aes.encrypt(encodedData!.bytes))
                try? ciphertext.write(to: URL(fileURLWithPath: filename))
            }
        } catch {
            print("(Wallet) failed to write wallet to disk '\(error)', serious error: exiting")
            exit(0)
        }
        
    }
    
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
