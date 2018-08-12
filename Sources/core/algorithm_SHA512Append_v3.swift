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

public class AlgorithmSHA512AppendV3: AlgorithmProtocol {
    
    /*
     *      Same as v3, but smaller window for entry and longer matches
     */
    
    public static let seed = "BadgerBadgerDuckDuck".bytes.sha512()
    public static let distribution: [Int] = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,5,5,5,5,5,5,5,5,5,5,10,10,10,10,10,10,10,20,20,20,20,20,20,20,50,50,50,50,50,100,100,100,100,100,500,500,500,500,1000,1000,1000,2000,2000,2000,5000]
    public static let rounds = 9000
    public static let window = UInt8(16)
    public static var cache: [(String,Int)]?
    static var lock: Mutex = Mutex()
    
    public class func beans() -> [(String,Int)] {
        
        var retValue: [(String,Int)]?
        
        lock.mutex {
            
            if cache != nil {
                
                retValue = cache
                
            } else {
                
                var seedData: [UInt8] = []
                seedData.append(contentsOf: seed.sha512())
                while seedData.count < (rounds * 4) {
                    seedData.append(contentsOf: seedData.sha512())
                }
                
                var b: [(String,Int)] = []
                while true {
                    
                    for value in distribution {
                        
                        let key = Array(seedData.prefix(4)).toHexString()
                        b.append((key, value))
                        seedData.removeFirst(4)
                        
                        if b.count == rounds {
                            break;
                        }
                        
                    }
                    
                    if b.count == rounds {
                        break;
                    }
                    
                }
                
                cache = b
                
                retValue = b
            }
        }
        return retValue!
        
    }
    
    public func generate(ore: Ore, address: [UInt32]) -> Token {
        
        return Token(oreHeight: ore.height, address: address, algorithm: .SHA512_AppendV3)
        
    }
    
    public func validate(token: Token) -> Bool {
        
        // well the token is always valid, but does it meet any of the conditions
        let hash = self.hash(token: token)
        if hash[0] == Config.MagicByte && hash.sha512()[0] >= (Config.MagicByte - AlgorithmSHA512AppendV3.window) {
            
            //TODO: more validation here to ensure it is valid, against the workload me thinks
            return true
            
        } else {
            
            return false
            
        }
        
    }
    
    public func deprecated(height: UInt) -> Bool {
        return false
    }
    
    public func hash(token: Token) -> [UInt8] {
        
        var byteArray: [UInt8] = []
        
        for i in token.address {
            try? byteArray.append(contentsOf: Array(Ore.atHeight(token.oreHeight).rawMaterial[Int(i)...Int((Int(i)+Config.TokenSegmentSize)-1)]))
        }
        
        return byteArray.sha512()
        
    }
    
    public func workload(token: Token) -> Workload {
        
        let workload = Workload()
        var hash = self.hash(token: token)
        
        if hash[0] == Config.MagicByte && hash[1] >= (Config.MagicByte - AlgorithmSHA512AppendV3.window) {
            
            // we are through the gate, so lets see if we can find some magic beans in the hash
            // do it string based, because weirdly swift is pretty damn fast finding strings in strings plus I do it with 5 chars, or 2.5 bytes to fuck up dedicated hardware!
            let strHash = hash.toHexString()
            
            for k in AlgorithmSHA512AppendV3.beans() {
                
                if strHash.contains(string: k.0) {
                    workload.beans.append(k.0)
                }
                
            }
            
        }
        
        return workload
        
    }
    
    public func value(token: Token) -> UInt32 {
        
        // generate the workload signature, and send it to the Economy class for valuation
        let workload = self.workload(token: token)
        return Economy.value(token: token, workload: workload)
        
    }
    
    
}

