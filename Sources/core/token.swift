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

public enum TokenError : Error {
    case InvalidToken
    case InvalidTokenHeight
    case InvalidTokenAlgorithm
    case InvalidTokenAddress
}

public class Token {
    
    public var oreHeight: UInt32
    public var address: [UInt32]
    public var algorithm: AlgorithmType
    
    public init(oreHeight: UInt32, address: [UInt32], algorithm: AlgorithmType) {
        
        self.oreHeight = oreHeight
        self.address = address
        self.algorithm = algorithm
        
    }
    
    public init(_ tokenString: String) throws {
        
        self.oreHeight = 0
        self.address = []
        self.algorithm = .SHA512_Append
        
        var segments = tokenString.components(separatedBy: "-")
        
        if segments.count < (3 + Config.TokenAddressSize) {
            throw TokenError.InvalidTokenAddress
        }
        
        let height = UInt32(segments[0], radix: 16)
        if height != nil {
            self.oreHeight = height!
        } else {
            throw TokenError.InvalidTokenHeight
        }
        segments.remove(at: 0)
        
        let algorithm = UInt16(segments[0], radix: 16)
        if algorithm != nil {
            self.algorithm = AlgorithmType(rawValue: algorithm!)!
        }else {
            throw TokenError.InvalidTokenAlgorithm
        }
        segments.remove(at: 0)
        segments.remove(at: 0) // remove the value segment as this is evaluated
        
        while segments.count > 0 {
            let address = UInt32(segments[0], radix: 16)
            if address != nil {
                self.address.append(address!)
            } else {
                throw TokenError.InvalidTokenAddress
            }
        }
        
    }
    
    // <height>-<algorithm>-<value>-<add1>..-..<add n>
    // FFFFFFFF-FFFF-FFFFFFFF-FFFFFFFF-FFFFFFFF-FFFFFFFF-FFFFFFFF-FFFFFFFF-FFFFFFFF-FFFFFFFF-FFFFFFFF
    public func tokenId() -> String {
        
        var id = "\(self.oreHeight.toHex())-\(self.algorithm.rawValue.toHex())-\(self.value().toHex())"
        
        for a in self.address {
            id = id + "-\(a.toHex())"
        }
        
        return id
        
    }
    
    public func value() -> UInt32 {
        
        return AlgorithmManager().value(token: self)
        
    }

    
}
