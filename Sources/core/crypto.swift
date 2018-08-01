//
//  crypto.swift
//  SharkCore
//
//  Created by Adrian Herridge on 18/06/2018.
//

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
    
    public class func isSigned(_ value: String, signature_bytes: [byte], public_key_bytes: [byte]) -> Bool {
        return Verify(public_key_bytes, value.bytes, signature_bytes)
    }
    
    public class func isSigned(_ value: String, signature: String, public_key: String) -> Bool {
        return isSigned(value, signature_bytes: (signature.base58DecodedData ?? Data()).bytes, public_key_bytes: (public_key.base58DecodedData ?? Data()).bytes)
    }
    
    public class func isSigned(_ value: String, signature: String, address: String) -> Bool {
        return isSigned(value ,signature: signature, public_key: String(address.suffix(address.count-Config.CurrencyNetworkAddress.count)))
    }
    
}
