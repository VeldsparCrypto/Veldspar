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
    
    /*
     
     After many...many iterations of reward for PoW systems, we always ended up with far too many smaller values.  This became problematic, because to send a transaction would mean the reallocation of 1000's of small value tokens.  We needed the reward to be almost entirely random but also marginally weighted to the smaller values for numerance.
     
     So, having been round and round the differing concepts, we decided to just go with the "magic beans" approach.  So still entirely luck based, but will produce what the system needs in a wide spread of values.
     
     below is the code:
     
     // 1's, 2's & 5's are more numerous, but allocation is still entirely random.
     let values: [Int] = [1,1,1,1,1,1,2,2,2,2,2,2,5,5,5,5,5,5,10,10,10,10,50,50,50,100,100,500,1000,2000,5000]
     let alphabet = ["1","2","3","4","5","6","7","8","9","0","a","b","c","d","e","f"]
     var results: [String:Int] = [:]
     
     while results.keys.count < 1000 {
     
     let key = alphabet[Int(arc4random_uniform(15))] +  alphabet[Int(arc4random_uniform(15))] + alphabet[Int(arc4random_uniform(15))] + alphabet[Int(arc4random_uniform(15))] + alphabet[Int(arc4random_uniform(15))] + alphabet[Int(arc4random_uniform(15))]
     let value = values[Int(arc4random_uniform(UInt32(values.count)))]
     
     results[key] = value
     
     }
     
     print(results)
     
     */
    
    public class func value(token: Token, workload: Workload) -> UInt32 {
        
    
        
        // value can be differentiated by many things, so switch on the implementation to start
        switch token.algorithm {
        case .SHA512_AppendV1:
            
            // now depricated
            // now iterate the workload to calculate the reward
            var value = 0
            for bean in workload.beans {
                for b in AlgorithmSHA512AppendV1.beans() {
                    if bean == b.0 {
                        if b.1 > value {
                            value = b.1
                        }
                    }
                }
                
                return UInt32(value)
            }
            
        case .SHA512_AppendV2:
            
            // now depricated
            // now iterate the workload to calculate the reward
            var value = 0
            for bean in workload.beans {
                for b in AlgorithmSHA512AppendV2.beans() {
                    if bean == b.0 {
                        if b.1 > value {
                            value = b.1
                        }
                    }
                }
                
                return UInt32(value)
            }
            
        case .SHA512_AppendV3:
            
            // now iterate the workload to calculate the reward
            var value = 0
            for bean in workload.beans {
                for b in AlgorithmSHA512AppendV3.beans() {
                    if bean == b.0 {
                        if b.1 > value {
                            value = b.1
                        }
                    }
                }
                
                return UInt32(value)
            }
            
        }
        
        return UInt32(0)
        
    }

}
