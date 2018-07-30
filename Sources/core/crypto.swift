//
//  crypto.swift
//  SharkCore
//
//  Created by Adrian Herridge on 18/06/2018.
//

import Foundation

public class keys {
    
    var public_spend_key: [UInt8]?
    var secret_spend_key: [UInt8]?
    
    public func address() -> String {
        return "\(Config.CurrencyNetworkAddress)\(public_spend_key?.toBase64())"
    }
    
}
