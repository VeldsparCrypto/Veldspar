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

public enum AlgorithmType : UInt16 {
    case SHA512_Append = 0
}

protocol AlgorithmProtocol {
    func generate(ore: Ore, address: [UInt32]) -> Token
    func validate(token: Token) -> Bool
    func deprecated(height: UInt) -> Bool
    func hash(token: Token) -> [UInt8]
    func value(token: Token) -> UInt32
    func workload(token: Token) -> Workload
}

class AlgorithmManager {
    
    // the singleton
    static private var this = AlgorithmManager()
    
    // hold an array of all of the implementations
    private var implementations: [AlgorithmProtocol] = []
    private var lock: Mutex = Mutex()
    
    init() {
        register(algorithm: AlgorithmSHA512Append())
    }
    
    public func register(algorithm: AlgorithmProtocol) {
        lock.mutex {
            implementations.append(algorithm)
        }
    }
    
    public class func sharedInstance() -> AlgorithmManager {
        
        return AlgorithmManager.this
    }
    
    public func generate(type: AlgorithmType, ore: Ore, address: [UInt32]) -> Token? {
        
        var token: Token? = nil
        
        lock.mutex {
            if type.rawValue < implementations.count {
                let imp = implementations[Int(type.rawValue)]
                token = imp.generate(ore: ore, address: address)
            }
        }
        
        return token
        
    }
    
    public func validate(token: Token) -> Bool {
        
        var isValid: Bool = false
        
        lock.mutex {
            if token.algorithm.rawValue < implementations.count {
                let imp = implementations[Int(token.algorithm.rawValue)]
                isValid = imp.validate(token: token)
            }
        }
        
        return isValid
        
    }
    
    public func depricated(type: AlgorithmType, height: UInt) -> Bool? {
        
        var isDepricated: Bool = false
        
        lock.mutex {
            if type.rawValue < implementations.count {
                let imp = implementations[Int(type.rawValue)]
                isDepricated = imp.deprecated(height: height)
            }
        }
        
        return isDepricated
        
    }
    
    public func hash(token: Token) -> [UInt8] {
        
        var hash: [UInt8] = []
        
        lock.mutex {
            if token.algorithm.rawValue < implementations.count {
                let imp = implementations[Int(token.algorithm.rawValue)]
                hash = imp.hash(token: token)
            }
        }
        
        return hash

    }
    
    public func value(token: Token) -> UInt32 {
        
        var value: UInt32 = 0
        
        lock.mutex {
            if token.algorithm.rawValue < implementations.count {
                let imp = implementations[Int(token.algorithm.rawValue)]
                value = imp.value(token: token)
            }
        }
        
        return value
        
    }
    
}
