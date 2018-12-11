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

// defines

public enum CryptoHashType {
    case short10
    case sha224
    case sha256
    case sha512
    case md5
}

public var debug_on = false

public func debug(_ output: String) {
    if debug_on {
        print("[DEBUG] \(Date()) : \(output)")
    }
}

public func consensusTime() -> Int {
    return Int(UInt64(Date().timeIntervalSince1970 * 1000))
}

public extension Array where Element == UInt8 {
    
    public func toHexSegmentString() -> String {
        
        var values: [String] = []
        
        for b in self {
            values.append(b.toHex())
        }
        
        return values.joined(separator: "-")
        
    }
}

public extension String {
    public func CryptoHash() -> String {
        switch Config.DefaultHashType {
        case .sha224:
            return self.sha224()
        case .sha256:
            return self.sha256()
        case .sha512:
            return self.sha512()
        case .md5:
            return self.md5()
        case .short10:
            return self.sha224().prefix(10).lowercased()
        }
    }
}

public extension UInt64 {
    private func rawBytes() -> [UInt8] {
        let totalBytes = MemoryLayout<UInt64>.size
        var value = self
        return withUnsafePointer(to: &value) { valuePtr in
            return valuePtr.withMemoryRebound(to: UInt8.self, capacity: totalBytes) { reboundPtr in
                return Array(UnsafeBufferPointer(start: reboundPtr, count: totalBytes))
            }
        }
    }
    func toHex() -> String {
        let byteArray = self.rawBytes().reversed()
        return byteArray.map{String(format: "%02X", $0)}.joined()
    }
}

public extension Int {
    private func rawBytes() -> [UInt8] {
        let totalBytes = MemoryLayout<UInt32>.size
        var value = UInt32(self)
        return withUnsafePointer(to: &value) { valuePtr in
            return valuePtr.withMemoryRebound(to: UInt8.self, capacity: totalBytes) { reboundPtr in
                return Array(UnsafeBufferPointer(start: reboundPtr, count: totalBytes))
            }
        }
    }
    func toHex() -> String {
        let byteArray = self.rawBytes().reversed()
        return byteArray.map{String(format: "%02X", $0)}.joined()
    }
}

public extension UInt32 {
    private func rawBytes() -> [UInt8] {
        let totalBytes = MemoryLayout<UInt32>.size
        var value = self
        return withUnsafePointer(to: &value) { valuePtr in
            return valuePtr.withMemoryRebound(to: UInt8.self, capacity: totalBytes) { reboundPtr in
                return Array(UnsafeBufferPointer(start: reboundPtr, count: totalBytes))
            }
        }
    }
    func toHex() -> String {
        let byteArray = self.rawBytes().reversed()
        return byteArray.map{String(format: "%02X", $0)}.joined()
    }
}

public extension UInt16 {
    private func rawBytes() -> [UInt8] {
        let totalBytes = MemoryLayout<UInt16>.size
        var value = self
        return withUnsafePointer(to: &value) { valuePtr in
            return valuePtr.withMemoryRebound(to: UInt8.self, capacity: totalBytes) { reboundPtr in
                return Array(UnsafeBufferPointer(start: reboundPtr, count: totalBytes))
            }
        }
    }
    func toHex() -> String {
        let byteArray = self.rawBytes().reversed()
        return byteArray.map{String(format: "%02X", $0)}.joined()
    }
}

public extension UInt8 {
    private func rawBytes() -> [UInt8] {
        let totalBytes = MemoryLayout<UInt8>.size
        var value = self
        return withUnsafePointer(to: &value) { valuePtr in
            return valuePtr.withMemoryRebound(to: UInt8.self, capacity: totalBytes) { reboundPtr in
                return Array(UnsafeBufferPointer(start: reboundPtr, count: totalBytes))
            }
        }
    }
    func toHex() -> String {
        let byteArray = self.rawBytes().reversed()
        return byteArray.map{String(format: "%02X", $0)}.joined()
    }
}

struct Base58 {
    static let base58Alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    
    // Encode
    static func base58FromBytes(_ bytes: [UInt8]) -> String {
        var bytes = bytes
        var zerosCount = 0
        var length = 0
        
        for b in bytes {
            if b != 0 { break }
            zerosCount += 1
        }
        
        bytes.removeFirst(zerosCount)
        
        let size = bytes.count * 138 / 100 + 1
        
        var base58: [UInt8] = Array(repeating: 0, count: size)
        for b in bytes {
            var carry = Int(b)
            var i = 0
            
            for j in 0...base58.count-1 where carry != 0 || i < length {
                carry += 256 * Int(base58[base58.count - j - 1])
                base58[base58.count - j - 1] = UInt8(carry % 58)
                carry /= 58
                i += 1
            }
            
            assert(carry == 0)
            
            length = i
        }
        
        // skip leading zeros
        var zerosToRemove = 0
        var str = ""
        for b in base58 {
            if b != 0 { break }
            zerosToRemove += 1
        }
        base58.removeFirst(zerosToRemove)
        
        while 0 < zerosCount {
            str = "\(str)1"
            zerosCount -= 1
        }
        
        for b in base58 {
            str = "\(str)\(base58Alphabet[String.Index(encodedOffset: Int(b))])"
        }
        
        return str
    }
    
    // Decode
    static func bytesFromBase58(_ base58: String) -> [UInt8] {
        // remove leading and trailing whitespaces
        let string = base58.trimmingCharacters(in: CharacterSet.whitespaces)
        
        guard !string.isEmpty else { return [] }
        
        var zerosCount = 0
        var length = 0
        for c in string {
            if c != "1" { break }
            zerosCount += 1
        }
        
        let size = string.lengthOfBytes(using: String.Encoding.utf8) * 733 / 1000 + 1 - zerosCount
        var base58: [UInt8] = Array(repeating: 0, count: size)
        for c in string where c != " " {
            // search for base58 character
            guard let base58Index = base58Alphabet.index(of: c) else { return [] }
            
            var carry = base58Index.encodedOffset
            var i = 0
            for j in 0...base58.count where carry != 0 || i < length {
                carry += 58 * Int(base58[base58.count - j - 1])
                base58[base58.count - j - 1] = UInt8(carry % 256)
                carry /= 256
                i += 1
            }
            
            assert(carry == 0)
            length = i
        }
        
        // skip leading zeros
        var zerosToRemove = 0
        
        for b in base58 {
            if b != 0 { break }
            zerosToRemove += 1
        }
        base58.removeFirst(zerosToRemove)
        
        var result: [UInt8] = Array(repeating: 0, count: zerosCount)
        for b in base58 {
            result.append(b)
        }
        return result
    }
}



public extension Array where Element == UInt8 {
    public var base58EncodedString: String {
        guard !self.isEmpty else { return "" }
        return Base58.base58FromBytes(self)
    }
    
    public var base58CheckEncodedString: String {
        var bytes = self
        let checksum = [UInt8](bytes.sha256().sha256()[0..<4])
        
        bytes.append(contentsOf: checksum)
        
        return Base58.base58FromBytes(bytes)
    }
}

public extension String {
    
    public var hexToData: Data {
        
        var d = Data()
        var copy = self
        
        while copy.count > 0 {
            let byte = copy.prefix(2).uppercased()
            copy.removeFirst(2)
            d.append(UInt8(byte, radix: 16)!)
        }
        
        return d
        
    }
    
    public var base58EncodedString: String {
        return [UInt8](utf8).base58EncodedString
    }
    
    public var base58DecodedData: Data? {
        let bytes = Base58.bytesFromBase58(self)
        return Data(bytes)
    }
    
    public var base58CheckDecodedData: Data? {
        guard let bytes = self.base58CheckDecodedBytes else { return nil }
        return Data(bytes)
    }
    
    public var base58CheckDecodedBytes: [UInt8]? {
        var bytes = Base58.bytesFromBase58(self)
        guard 4 <= bytes.count else { return nil }
        
        let checksum = [UInt8](bytes[bytes.count-4..<bytes.count])
        bytes = [UInt8](bytes[0..<bytes.count-4])
        
        let calculatedChecksum = [UInt8](bytes.sha256().sha256()[0...3])
        if checksum != calculatedChecksum { return nil }
        
        return bytes
    }
    
}

#if os(Linux)
import SwiftGlibc

public func arc4random_uniform(_ max: UInt32) -> Int32 {
    return (SwiftGlibc.rand() % Int32(max-1))
}
#endif

#if swift(>=4.2)
#else
public extension MutableCollection {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            // Change `Int` in the next line to `IndexDistance` in < Swift 4.1
            let d: Int = Int(arc4random_uniform(UInt32(unshuffledCount)))
            let i = index(firstUnshuffled, offsetBy: d)
            swapAt(firstUnshuffled, i)
        }
    }
}

public extension Sequence {
    /// Returns an array with the contents of this sequence, shuffled.
    func shuffled() -> [Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
}
#endif

