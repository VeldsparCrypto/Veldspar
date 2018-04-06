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

enum TokenHashingAlgorithm : UInt8 {
    case sha224 = 0
    case sha256 = 1
    case sha384 = 2
    case sha512 = 3
}

enum TokenCombinationMethod : UInt8 {
    case append = 0
    case prepend = 1
}

class Token {
    
    var height: UInt32
    var address: [UInt32]
    var algorithm: TokenHashingAlgorithm
    var method: TokenCombinationMethod
    var value: UInt32
    
    init(height: UInt32, address: [UInt32], algo: TokenHashingAlgorithm, method: TokenCombinationMethod) {
        
        self.height = height
        self.address = address
        self.algorithm = algo
        self.method = method
        self.value = 0
        self.value = Economy.valueForToken(self)
        
    }
    
    
    // <height><method><algorithm><value><add1>..<add n>
    // FFFFFFFFFFFFFFFF-FF-FF-FFFFFFFF-FFFFFFFF-FFFFFFFF-FFFFFFFF-FFFFFFFF-FFFFFFFF-FFFFFFFF-FFFFFFFF-FFFFFFFF
    func tokenId() -> String {
        var id = "\(self.height.toHex())-\(self.method.rawValue.toHex())-\(self.algorithm.rawValue.toHex())-\(self.value.toHex())"
        
        for a in self.address {
            id = id + "-\(a.toHex())"
        }
        
        return id
    }
    
    func tokenHash() -> [UInt8] {
        
        do {
            let ore = try Ore.atHeight(self.height)
            
            var byteArray: [UInt8] = []
            
            switch self.method {
            case .append:
                for i in self.address {
                    byteArray.append(contentsOf: Array(ore.rawMaterial[Int(i)...Int(Int(i)+Config.TokenSegmentSize)]))
                }
            case .prepend:
                for i in self.address {
                    byteArray.insert(contentsOf: Array(ore.rawMaterial[Int(i)...Int(Int(i)+Config.TokenSegmentSize)]), at: 0)
                }
            }
            
            switch self.algorithm {
            case .sha224:
                return byteArray.sha224()
            case .sha512:
                return byteArray.sha512()
            case .sha256:
                return byteArray.sha256()
            case .sha384:
                return byteArray.sha384()
            }
            
        } catch {
            
            return []
            
        }
    
    }
    
    func validate() -> Bool {
        
        // well the token is always valid, but does it meet any of the conditions
        let hash = self.tokenHash()
        if hash.starts(with: [Economy.patternByte]) {
            
            //TODO: more validation here to ensure it is valid
            return true
            
        } else {
            
            return false
            
        }
        
    }
    
    func patternByteCount() -> Int {
        
        // well the token is always valid, but does it meet any of the conditions
        let hash = self.tokenHash()
        if hash.starts(with: [Economy.patternByte]) {
            
            // now see how many we have at the start
            var count = 1
            for i in 1...Economy.patternValue.count-1 {
                if hash[i] == Economy.patternByte {
                    count += 1
                } else {
                    break
                }
            }
            
            return count
            
        }
        
        return 0
        
    }
    
    func iterativeMatches() -> Int {
        
        // well the token is always valid, but does it meet any of the conditions
        var hash = self.tokenHash()
        var startHash = self.tokenHash()
        var count = 0
        
        while hash.starts(with: [Economy.patternByte]) {
            
            switch self.algorithm {
            case .sha224:
                hash = Array(hash.sha224())
            case .sha256:
                hash = Array(hash.sha256())
            case .sha384:
                hash = Array(hash.sha384())
            case .sha512:
                hash = Array(hash.sha512())
            }
            
            if hash.starts(with: [Economy.patternByte]) {
                count += 1
            }
            
        }
        
        return count
        
    }
    
}
