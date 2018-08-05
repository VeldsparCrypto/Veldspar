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
    
    // the 'magic beans' table, is an assortment of random sequences which have value.  This stops the programatic discovery of only small value tokens.  Which would result in transactions which are far too numberous (e.g. sending 1000 veldspar would result in 10,000 token re-allocations)
    public static let magicBeans : [AlgorithmType : [Int /* active block height */ : [String:Int]]] =
        [
            AlgorithmType.SHA512_Append : [ 0 :
                
                ["b5cd": 1, "9e77": 2, "c1b0": 10, "08a0": 10, "bd18": 50, "3bad": 1, "18bd": 1, "ed64": 2, "3d24": 5, "ed53": 10, "34c6": 10, "923a": 1, "d513": 10, "6c03": 5, "80ab": 50, "7750": 1, "7de0": 100, "e00b": 50, "c2b4": 1, "5bb6": 50, "b5c6": 5, "6976": 1000, "3042": 1000, "c25a": 5, "aeaa": 50, "de23": 5, "a41c": 5, "d2b4": 5, "7380": 50, "398e": 1, "1b3b": 2, "0295": 1, "d9d3": 100, "4c92": 2, "23b4": 500, "4bc0": 1, "c2c0": 10, "70e0": 5, "39ba": 5000, "60ec": 5, "5729": 50, "c21c": 10, "3ba9": 1, "a1ba": 50, "7e56": 2, "c5d9": 10, "77ac": 100, "77d0": 2, "00a0": 2, "632c": 2, "1e6a": 5, "c857": 500, "5a46": 2, "e795": 10, "4de3": 2, "882b": 50, "8d67": 1, "305a": 500, "55ad": 2000, "e325": 50, "435b": 5, "1680": 5, "c38b": 50, "69dc": 5000, "10da": 500, "5539": 100, "d8ac": 2000, "3547": 2, "812e": 5, "01c3": 5, "4c00": 50, "d066": 1, "d0c1": 5, "b11a": 1, "2ba4": 50, "a070": 50, "3c8b": 50, "363e": 5, "9e46": 5, "b3ee": 10, "0580": 50, "7112": 2, "c60c": 10, "8183": 50, "6d0c": 50, "07c2": 5, "a095": 2000, "1362": 1, "a94b": 5, "bc47": 100, "e6a1": 2, "0362": 1, "6a94": 50, "b34a": 5, "e0db": 10, "d3b6": 5, "252e": 2, "b05d": 2, "dad6": 2, "4ccd": 2]

            ]
    ]
    
    public class func value(token: Token, workload: Workload) -> UInt32 {
        
        var value = 0
        
        // value can be differentiated by many things, so switch on the implementation to start
        switch token.algorithm {
        case .SHA512_Append:
            
            // find the beans table appropriate to the ore height
            let algoTable: [Int /* active block height */ : [String:Int]] = magicBeans[AlgorithmType.SHA512_Append]!
            
            let rewards = algoTable[Int(token.oreHeight)]!
            
            // now iterate the workload to calculate the reward
            for bean in workload.beans {
                
                value += rewards[bean]!
                
            }
            
        }
        
        return UInt32(value)
        
    }
    
}
