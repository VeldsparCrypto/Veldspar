//    MIT License
//
//    Copyright (c) 2018 Veldspar Team
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.

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
