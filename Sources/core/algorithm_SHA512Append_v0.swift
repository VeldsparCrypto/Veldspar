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

public class AlgorithmSHA512AppendV0: AlgorithmProtocol {
    
    /*
     *      new v0 algo, relies on previous rounds to validate.  Stops pre-calculation, stops GUP parralisum
     */
    
    public let seed = "BoyBellSproutMouse".data(using: .ascii)!.bytes.sha512()
    public let distribution: [Int] = [50,100,1,500,2,2,2000,5,1,5,10,10,20,20,50,5,200,1,1000,2,5000]
    public let beanBytes = 1
    public let requiredDepth = 1
    public let hashSearchLength = 64

    public func deprecated(height: UInt) -> Bool {
        return true
    }
    
    public func value(token: Token) -> Int {
        
        // generate the workload signature, and send it to the Economy class for valuation
        var byteArray: [UInt8] = []
        var address = token.address.toHexString()
        
        while address.count > 0 {
            
            let d = address.prefix(8)
            address.removeFirst(8)
            let i = Int(UInt32(d, radix:16)!)
            
            try? byteArray.append(contentsOf: Array(Ore.atHeight(token.oreHeight).rawMaterial[Int(i)...Int((Int(i)+Config.TokenSegmentSize)-1)]))
            
        }
        
        var hash = byteArray.sha512()
        var currentDepth = 0
        var currentValue = 0
        while currentDepth < requiredDepth {
            
            if hash[0] == Config.MagicByte {
                
                currentValue = 0
                
                // we are through the gate, so lets generate magic beans from this hash
                var beans: [Data] = []
                var beanSource: Data = Data(bytes: hash.sha512()) // this is always 5x hash
                for _ in 1...4 {
                    beanSource.append(contentsOf: beanSource.bytes.sha512())
                }
                
                // pull out the patterns
                for _ in distribution {
                    beans.append(beanSource.suffix(beanBytes))
                    beanSource.removeLast(beanBytes)
                }

                let hashData = Data(hash).prefix(upTo: hashSearchLength)
                var selectedBean: Data?
                
                
                for b in beans {
                    if hashData.range(of: b) != nil {
                        selectedBean = b
                        if currentValue == 0 {
                            currentValue = distribution[beans.index(of: b)!]
                            break
                        }
                    }
                }
                
                if selectedBean != nil {
                    
                    // we have a match, so increment the depth
                    currentDepth += 1
                    
                    // genearate a new hash, based on the existing hash with the found bean replacing the bytes at the front of the array
                    hash.removeFirst(beanBytes)
                    hash.insert(contentsOf: selectedBean!.bytes, at: 0)
                    hash = hash.sha512()
                    
                } else {
                    break
                }
                
            } else if currentDepth == requiredDepth {
                break
            } else {
                break
            }
            
            
        }
        
        if currentDepth == requiredDepth {
            // boom, lets go and get the value
            return currentValue
        }

        return 0
        
    }
    
}
