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
    
    public var oreHeight: Int
    public var location: [Int]
    public var algorithm: AlgorithmType
    private var cachedValue: Int?
    
    public init(oreHeight: Int, location: [Int], algorithm: AlgorithmType) {
        
        self.oreHeight = oreHeight
        self.location = location
        self.algorithm = algorithm
        
    }
    
    public init(_ tokenString: String) throws {
        
        self.oreHeight = 0
        self.location = []
        self.algorithm = .SHA512_AppendV1
        
        var segments = tokenString.components(separatedBy: "-")
        
        if segments.count < (3 + Config.TokenAddressSize) {
            throw TokenError.InvalidTokenAddress
        }
        
        let height = Int(segments[0], radix: 16)
        if height != nil {
            self.oreHeight = height!
        } else {
            throw TokenError.InvalidTokenHeight
        }
        segments.remove(at: 0)
        
        let algorithm = UInt16(segments[0], radix: 16)
        if algorithm != nil {
            if algorithm! < AlgorithmManager.sharedInstance().countOfAlgos() {
                self.algorithm = AlgorithmType(rawValue: algorithm!)!
            } else {
                // request for an unsupported algorithum .... hummmm
                throw TokenError.InvalidTokenAlgorithm
            }
        }else {
            throw TokenError.InvalidTokenAlgorithm
        }
        segments.remove(at: 0)
        segments.remove(at: 0) // remove the value segment as this is evaluated
        
        while segments.count > 0 {
            let address = Int(segments[0], radix: 16)
            if address != nil {
                self.location.append(address!)
                segments.remove(at: 0)
            } else {
                throw TokenError.InvalidTokenAddress
            }
        }
        
    }
    
    // <height>-<algorithm>-<value>-<add1>..-..<add n>
    // FFFFFFFF-FFFF-FFFFFFFF-FFFFFFFF-FFFFFFFF-FFFFFFFF-FFFFFFFF-FFFFFFFF-FFFFFFFF-FFFFFFFF-FFFFFFFF
    public func tokenStringId() -> String {
        
        var id = "\(self.oreHeight.toHex())-\(self.algorithm.rawValue.toHex())-\(self.value().toHex())"
        
        for a in self.location {
            id = id + "-\(a.toHex())"
        }
        
        return id
        
    }
    
    public func value() -> Int {
        
        if cachedValue != nil {
            return cachedValue!
        }
        
        cachedValue = AlgorithmManager().value(token: self)
        return cachedValue!
        
    }

    public class func valueFromId(_ token: String) -> Int {
        
        var segments = token.components(separatedBy: "-")
        return Int(segments[2], radix: 16)!
        
    }
    
}
