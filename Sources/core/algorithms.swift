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

public enum AlgorithmType : Int {
    case SHA512_AppendV0 = 0
    case SHA512_AppendV1 = 1
}

public protocol AlgorithmProtocol {
    func generate(ore: Ore, address: Data) -> Token
    func validate(token: Token) -> Bool
    func deprecated(height: UInt) -> Bool
    func hash(token: Token) -> [UInt8]
    func value(token: Token) -> Int
    func workload(token: Token) -> Workload
    func validateFind(token: Token, bean: Data) -> Bool
    func foundBean(token: Token) -> Data?
}

public class AlgorithmManager {
    
    // the singleton
    static private var this = AlgorithmManager()
    
    // hold an array of all of the implementations
    private var implementations: [AlgorithmProtocol] = []
    private var lock: Mutex = Mutex()
    
    init() {
        register(algorithm: AlgorithmSHA512AppendV0())
        register(algorithm: AlgorithmSHA512AppendV1())
    }
    
    public func countOfAlgos() -> Int {
        
        var count = 0
        
        lock.mutex {
            count = self.implementations.count
        }
        
        return count
        
    }
    
    public func register(algorithm: AlgorithmProtocol) {
        lock.mutex {
            self.implementations.append(algorithm)
        }
    }
    
    public class func sharedInstance() -> AlgorithmManager {
        
        return AlgorithmManager.this
    }
    
    public func generate(type: AlgorithmType, ore: Ore, address: Data) -> Token? {
        
        var token: Token? = nil
        
        lock.mutex {
            if type.rawValue < self.implementations.count {
                let imp = self.implementations[Int(type.rawValue)]
                token = imp.generate(ore: ore, address: address)
            }
        }
        
        return token
        
    }
    
    public func validate(token: Token) -> Bool {
        
        var isValid: Bool = false
        
        lock.mutex {
            if token.algorithm.rawValue < self.implementations.count {
                let imp = self.implementations[Int(token.algorithm.rawValue)]
                isValid = imp.validate(token: token)
            }
        }
        
        return isValid
        
    }
    
    public func depricated(type: AlgorithmType, height: UInt) -> Bool {
        
        var isDepricated: Bool = false
        
        lock.mutex {
            if type.rawValue < self.implementations.count {
                let imp = self.implementations[Int(type.rawValue)]
                isDepricated = imp.deprecated(height: height)
            }
        }
        
        return isDepricated
        
    }
    
    public func hash(token: Token) -> [UInt8] {
        
        var hash: [UInt8] = []
        
        lock.mutex {
            if token.algorithm.rawValue < self.implementations.count {
                let imp = self.implementations[Int(token.algorithm.rawValue)]
                hash = imp.hash(token: token)
            }
        }
        
        return hash

    }
    
    public func value(token: Token) -> Int {
        
        var value: Int = 0
        
        lock.mutex {
            if token.algorithm.rawValue < self.implementations.count {
                let imp = self.implementations[Int(token.algorithm.rawValue)]
                value = imp.value(token: token)
            }
        }
        
        return value
        
    }
    
    public func foundBean(token: Token) -> Data? {
        
        var value: Data? = nil
        
        lock.mutex {
            if token.algorithm.rawValue < self.implementations.count {
                let imp = self.implementations[Int(token.algorithm.rawValue)]
                value = imp.foundBean(token: token)
            }
        }
        
        return value
        
    }
    
    public func validate(token: Token, bean: String) -> Bool {
        
        var retValue: Bool = false
        
        lock.mutex {
            if token.algorithm.rawValue < self.implementations.count {
                let imp = self.implementations[Int(token.algorithm.rawValue)]
                retValue = imp.validateFind(token: token, bean: bean.hexToData)
            }
        }
        
        return retValue
        
    }
    
}
