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

public class Economy {
    
    // value of certain operations on the ore
    static let simpleOpValue = 1
    static let splitOpValue = 2
    static let orderOpValue = 3
    
    // value of the pattern, given the complexity of the hashing algo
    static let sha224Value = 1
    static let sha256Value = 1
    static let sha384Value = 1
    static let sha512Value = 1
    
    // pattern values - the value assigned given the chance of matching the pattern
    // token hash ff7a6c6b53c2e2a would have a value of 0
    // token hash fff7a6c6b53c2e2 would have a value of 1
    // token hash ffff7a6c6b53c2e would have a value of 10
    // etc.....

    static let patternByte = UInt8(255)
    static let patternValue: [UInt32] = [0,0,1,100,10000,100000,1000000]
    
    // sequential match value - additional value for all the subsequent sequential hashes which start with the patternByte
    static let sequentialMatch = [10,100,1000,10000,100000,1000000]
    
    // match reward bytes - number of bytes (minus pattern matched) to attribute value for
    static let matchRewardBytes = 16
    
    // match reward matrix - value awarded for number of additional bytes up to `matchRewardBytes`
    static let matchRewardMatrix: [UInt32] = [1,10,20,40,80,160,320,640,1280,2560,5120,10240]
    
    // value == (OP x PatternValue x AlgoValue) + Sequential Value + (patternByte count for first 32 bytes)
    
    public class func valueForToken(_ token: Token) -> UInt32 {
        
        // well the token is always valid, but does it meet any of the conditions
        let hash = token.tokenHash()
        if hash.starts(with: [patternByte]) {
            
            let count = token.patternByteCount()
            let patFindValue = patternValue[count]
            var opValue = 0
            var algoValue = 0
            
            switch token.method {
            case .append:
                opValue = simpleOpValue
            case .prepend:
                opValue = simpleOpValue
            }
            
            switch token.algorithm {
            case .sha224:
                algoValue = sha224Value
            case .sha256:
                algoValue = sha256Value
            case .sha384:
                algoValue = sha384Value
            case .sha512:
                algoValue = sha512Value
            }
            
            
            
            // value == (OP x PatternValue x AlgoValue) + Sequential Value + (patternByteCount first 24 bytes)
            
            var value: UInt32 = (UInt32(opValue) * UInt32(patFindValue)) * UInt32(algoValue)
            
            if value > 0 {
                
                // now find the sequential value, by interating the hash, and seeing how many matching bytes are found
                let iterativeMatches = token.iterativeMatches()
                
                if iterativeMatches > 0 {
                    value += UInt32(sequentialMatch[iterativeMatches])
                }

                var byteCount = 0
                for i in count...24 {
                    if hash[i] == patternByte {
                        byteCount += 1
                    }
                }
                
                // now to add some variance to the valuation, see how many times that patternByte appears in the first 24 bytes.  Excuding the starting matches which have already been rewarded.

                value += UInt32(byteCount)
                
            }

            return value
            
        } else {
            return UInt32(0)
        }
        
    }
    
}
