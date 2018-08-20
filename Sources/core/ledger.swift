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
    public var block: UInt32
    
    public init(op: LedgerOPType,token: String, ref: String, address: String, auth: String, block: UInt32) {
        
        self.transaction_id = UUID().uuidString.CryptoHash()
        self.op = op
        self.transaction_group = ref
        self.destination = address
        self.date = consensusTime()
        self.spend_auth = auth
        self.block = block
        self.token = token
        
    }
    
    public init(id: String, op: LedgerOPType, token: String, ref: String, address: String, date: UInt64, auth: String, block: UInt32) {
        
        self.transaction_id = id
        self.op = op
        self.transaction_group = ref
        self.destination = address
        self.date = date
        self.spend_auth = auth
        self.block = block
        self.token = token
        
    }
    
    public func addresses() -> [UInt64] {
        
        var addresses: [UInt64] = []
        
        var components = token.components(separatedBy: "-")
        components.remove(at: 0) // ore
        components.remove(at: 0) // algo
        components.remove(at: 0) // value
        
        for a in components {
            addresses.append(UInt64(a, radix: 16) ?? 0)
        }
        
        return addresses
        
    }
    
    public func checksum() -> String {
        return "\(transaction_id)\(op.rawValue)\(date)\(transaction_group)\(destination)\(spend_auth)\(block)".md5()
    }
    
}
