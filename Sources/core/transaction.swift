//    MIT License
//
//    Copyright (c) 2018 SharkChain Team
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

public enum TransactionType: Int {
    case allocation = 0     // allocates new/discovered tokens to a public view key
    case transfer = 1       // transfers ownership of a token from one address to another
}

public class Transaction {
    
    public var id: String
    public var type: TransactionType
    public var key: String
    public var signature: String
    public var dest: String
    public var ref: String = ""
    public var value: Int = 0
    public var date: UInt64
    public var tokens: [String] = []
    
    public init(type: TransactionType, publicSpendKey: String, signature: String, dest: String, id: String) {
        self.type = type
        self.key = publicSpendKey
        self.signature = signature
        self.dest = dest
        self.id = id
        self.date = UInt64(Date().timeIntervalSince1970)
    }
    
}
