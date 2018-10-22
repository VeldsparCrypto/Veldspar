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

public class RPC_Block : Codable {
    
    public var height: Int?
    public var seed: String?
    public var hash: String?
    
    public var transactions: [RPC_Ledger] = []
    
    public init() {}
    
}

public class RPC_Ledger : Codable {
    
    public var transaction_id: String?
    public var op: Int?
    public var date: UInt64?
    public var transaction_ref: String?
    public var destination: String?
    public var auth: String?
    public var height: Int?
    public var ore: Int?
    public var algo: Int?
    public var value: Int?
    public var location: [Int]?
    
    public init() {}
    
    public func token() -> String {
        
        var components: [String] = []
        
        components.append("\(self.ore ?? 0)")
        components.append("\(self.algo ?? 0)")
        components.append("\(self.value ?? 0)")
        for l in location ?? [] {
            components.append("\(l)")
        }
        
        return components.joined(separator: "-")
        
    }
    
}
