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

enum LedgerTransactionState : Int {
    case New = 0
    case Verified = 1
    case Pending = 2
    case Rejected = 3
    case Accepted = 4
}

public class Ledger {

    public var op: LedgerOPType
    public var date: UInt64
    public var transaction_ref: String
    public var destination: String
    public var ore: Int
    public var algo: Int
    public var value: Int
    public var address: [UInt8]
    public var auth: String
    public var height: Int
    
    
    public init(op: LedgerOPType,token: String, ref: String, address: String, auth: String, height: Int, ore: Int, algo: Int, value: Int, location: [Int]) {
        
        self.transaction_id = UUID().uuidString.CryptoHash()
        self.op = op
        self.transaction_ref = ref
        self.destination = address
        self.date = consensusTime()
        self.auth = auth
        self.height = height
        self.ore = ore
        self.algo = algo
        self.value = value
        self.location = location
        
    }
    
    public init(id: String, op: LedgerOPType, ref: String, address: String, date: UInt64, auth: String, height: Int, ore: Int, algo: Int, value: Int, location: [Int]) {
        
        self.transaction_id = id
        self.op = op
        self.transaction_ref = ref
        self.destination = address
        self.date = date
        self.auth = auth
        self.height = height
        self.ore = ore
        self.algo = algo
        self.value = value
        self.location = location
        
    }
    
    public func checksum() -> String {
        return "\(transaction_id)\(op.rawValue)\(date)\(transaction_ref)\(destination)\(auth)\(height)\(algo)\(ore)\(location[0]))".md5()
    }
    
}
