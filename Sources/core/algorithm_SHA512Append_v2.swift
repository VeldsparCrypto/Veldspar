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

public class AlgorithmSHA512AppendV2: AlgorithmProtocol {
    
    /*
     *      Same as v1, but smaller window for entry but bigger rewards
     */
    
    
    public func generate(ore: Ore, address: [UInt32]) -> Token {
        
        return Token(oreHeight: ore.height, address: address, algorithm: .SHA512_AppendV2)
        
    }
    
    public class func beans() -> [(String,Int)] {
        return v2_beans;
    }
    
    public func validate(token: Token) -> Bool {
        
        // well the token is always valid, but does it meet any of the conditions
        let hash = self.hash(token: token)
        if hash[0] == Config.MagicByte && hash.sha512()[0] == Config.MagicByte {
            
            //TODO: more validation here to ensure it is valid, against the workload me thinks
            return true
            
        } else {
            
            return false
            
        }
        
    }
    
    public func deprecated(height: UInt) -> Bool {
        return true
    }
    
    public func hash(token: Token) -> [UInt8] {
        
        var byteArray: [UInt8] = []
        
        for i in token.address {
            try? byteArray.append(contentsOf: Array(Ore.atHeight(token.oreHeight).rawMaterial[Int(i)...Int(Int(i)+Config.TokenSegmentSize)]))
        }
        
        return byteArray.sha512()
        
    }
    
    public func workload(token: Token) -> Workload {
        
        let workload = Workload()
        var hash = self.hash(token: token)
        
        if hash[0] == Config.MagicByte && hash[1] >= (Config.MagicByte - 13) {
            
            // we are through the gate, so lets see if we can find some magic beans in the hash

            // do it string based, because weirdly swift is pretty damn fast finding strings in strings plus I do it with 5 chars, or 2.5 bytes to fuck up dedicated hardware!
            let strHash = hash.toHexString()
            
            for k in AlgorithmSHA512AppendV2.beans() {
                
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
