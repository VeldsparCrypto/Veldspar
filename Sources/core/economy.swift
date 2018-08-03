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
import CryptoSwift

/*
 *      The Economy class will take tokens and verify their value, based on the complexity of the workload used to produce it.
 */

public class Economy {
    
    // pattern values - the value assigned given the chance of matching the pattern
    // token hash ff7a6c6b53c2e2a would have a value of 0
    // token hash ffff7a6c6b53c2e2 would have a value of 1
    // token hash ffffff7a6c6b53c2e would have a value of 10
    // etc.....

    static let patternByte = UInt8(255)
    static let sequenceValue = [0,0,1,10,100,10000,100000,1000000]
    
    // sequential match value - additional value for all the subsequent sequential hashes which start with the patternByte
    static let iterationMatch = [0,0,100,1000,10000,100000,1000000,10000000]
    
    // match reward bytes - number of bytes (minus pattern matched) to attribute value for
    static let occurrencesRewardBytes = 24
    
    // match reward matrix - value awarded for number of additional bytes up to `matchRewardBytes`
    static let occurrencesRewardMatrix = [0,0,1,10,20,40,80,160,320,640,1280,2560,5120,10240]
    
    public class func value(token: Token, workload: Workload) -> UInt32 {
        
        var value = 0
        
        // value can be differentiated by many things, so switch on the implementation to start
        switch token.algorithm {
        case .SHA512_Append:
            value += sequenceValue[workload.sequence]
            // only if we have a sequence match allow secondary value to be added
            if value > 0 {
                value += iterationMatch[workload.iterations]
                value += occurrencesRewardMatrix[workload.occurrences]
            }
        }
        
        return UInt32(value)
        
    }
    
}
