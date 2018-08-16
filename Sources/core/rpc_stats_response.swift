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

public class RPC_StatsBlock : Codable {
    
    public var height = 0
    public var newTokens = 0
    public var newValue = 0
    public var depletion: Double = 0
    public var addressHeight = 0
    public var activeAddresses = 0
    public var reallocTokens = 0
    public var reallocValue = 0
    
    public var denominations: [String:Int] = [:]
    
    public init() {}
    
}

public class RPC_Stats : Codable {
    
    public var height = 0
    public var value: Double = 0.0
    public var tokens = 0
    public var blocks: [RPC_StatsBlock] = []
    public var denominations: [String:Int] = [:]
    public var depletion: Double = 0.0
    public var rate: Double = 0.0
    public var transactions: Int = 0
    public var addresses: Int = 0
    
    public init() {}
    
}
