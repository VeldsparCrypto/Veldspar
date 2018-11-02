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

public enum LedgerOPType : Int {
    
    case Unset = 0
    case RegisterToken = 1
    case ChangeOwner = 2
    case ReWriteToken = 3
    
}

public enum LedgerTransactionState : Int {
    
    case Pending = 0
    case Verified = 1
    
}

public struct Ledger : Codable {

    public var id: Int?
    public var op: Int?
    public var date: UInt64?
    public var transaction_ref: String?
    public var destination: String?
    public var ore: Int?
    public var address: Data?
    public var auth: String?
    public var height: Int?
    public var algorithm: Int?
    public var value: Int?
    public var state: Int?
    public var source_node: String?
    public var hash: String?
    
    public init() {
    }
    
    public func checksum() -> String {
        return "\(date ?? 0)\(transaction_ref ?? "")\(destination ?? "")\(auth ?? "")\(height ?? 0)\(algorithm ?? 0)\(ore ?? 0)\(address?.base64EncodedString() ?? ""))".md5()
    }
    
    public func token() -> Token? {
        return Token.init(oreHeight: self.ore ?? 0, address: self.address ?? Data(), algorithm: AlgorithmType(rawValue: self.algorithm ?? 0) ?? AlgorithmType.SHA512_AppendV0)
    }
    
}
