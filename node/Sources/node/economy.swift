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
import CryptoSwift

/*
 *      The Economy class will take tokens and verify their value, based on the complexity of the workload used to produce it.
 */

class Economy {
    
    // value of certain operations on the ore
    static let simpleOpValue = 1
    static let splitOpValue = 2
    static let orderOpValue = 3
    
    // value of the pattern, given the complexity of the hashing algo
    static let sha224Value = 1
    static let sha256Value = 2
    static let sha384Value = 4
    static let sha512Value = 8
    
    // token hash ff7a6c6b53c2e2a would have a value of 0
    // token hash fff7a6c6b53c2e2 would have a value of 1
    // etc.....

    static let patternValue = [0,0,1,10,100,1000,10000,100000,1000000,10000000,100000000]
    
    // value == OP x PatternValue x AlgoValue x Rounds
    
    class func validateToken(_ token: Token) -> Bool {
        
    }
    
    class func valueForToken(_ token: Token) -> UInt64 {
        
    }
    
}
