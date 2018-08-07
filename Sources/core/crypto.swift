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
import Ed25519

public class Keys {
    
    public var private_key: [byte]
    public var public_key: [byte]
    
    public init() {
        let seed = UUID().uuidString.sha224().data(using: String.Encoding.ascii)!.prefix(upTo: 32)
        let k = GenerateKey(seed.bytes)
        private_key = k.privateKey
        public_key = k.publicKey
    }
    
    public init(_ seed: [byte]) {
        let k = GenerateKey(seed)
        private_key = k.privateKey
        public_key = k.publicKey
    }
    
    public func address() -> String {
        return "\(Config.CurrencyNetworkAddress)\(public_key.base58EncodedString)"
    }
    
    public func sign(_ value: String) -> String {
        
        return Sign(private_key, value.bytes).base58EncodedString
        
    }
    
    public func isSigned(_ value: String, signature: String) -> Bool {
        return Verify(public_key, value.bytes, (signature.base58DecodedData ?? Data()).bytes)
    }
    
}

public class Crypto {
    
    public class func isSigned(_ value: String, signature_bytes: [byte], public_key_bytes: [byte]) -> Bool {
        return Verify(public_key_bytes, value.bytes, signature_bytes)
    }
    
    public class func isSigned(_ value: String, signature: String, public_key: String) -> Bool {
        return isSigned(value, signature_bytes: (signature.base58DecodedData ?? Data()).bytes, public_key_bytes: (public_key.base58DecodedData ?? Data()).bytes)
    }
    
    public class func isSigned(_ value: String, signature: String, address: String) -> Bool {
        return isSigned(value ,signature: signature, public_key: String(address.suffix(address.count-Config.CurrencyNetworkAddress.count)))
    }
    
    public class func makeTransactionIdentifier(src: String, dest: String, token: String) -> String {
        return "\(src)\(dest)\(token)".base58EncodedString
    }
    
}
