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

class AlgorithmSHA512Append: AlgorithmProtocol {
    
    
    func generate(ore: Ore, address: [UInt32]) -> Token {
        
        return Token(oreHeight: ore.height, address: address, algorithm: .SHA512_Append)
        
    }
    
    func validate(token: Token) -> Bool {
        
        // well the token is always valid, but does it meet any of the conditions
        let hash = try? self.hash(token: token)
        if hash!.starts(with: [Economy.patternByte]) {
            
            //TODO: more validation here to ensure it is valid
            return true
            
        } else {
            
            return false
            
        }
        
    }
    
    func deprecated(height: UInt) -> Bool {
        return false
    }
    
    func hash(token: Token) -> [UInt8] {
        
        var byteArray: [UInt8] = []
        
        for i in token.address {
            try? byteArray.append(contentsOf: Array(Ore.atHeight(token.oreHeight).rawMaterial[Int(i)...Int(Int(i)+Config.TokenSegmentSize)]))
        }
        
        return byteArray.sha512()
        
    }
    
    
}
