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
import SWSQLite
import VeldsparCore
import Ed25519
import CryptoSwift
import Rainbow

enum WalletErrors : Error {
    case UnableToEncrypt
    case InvalidPassword
    case InvalidSeed
}

class Address : Codable {
    
    var addressId: String?
    var seed: String?
    var height: Int?
    var name: String?
    
    public init() {}
    
}

class Transfer : Codable {
    
    var id: Int?
    var timestamp: Int?
    var transferRef: Data?
    var tokenValue: Int?
    var height: Int?
    var target: String?
    
    
    public init() {}
    
}

class Spent : Codable {
    
    var id: Int?
    var transferRef: Data?

    public init() {}
    
}

class WalletFile {
    
    private var db: SWSQLite
    private var pw: String
    private var addressCache: [String]?
    
    init(_ walletFilePath: String, password: String) {
        
        db = SWSQLite(path: "./", filename: walletFilePath)
        
        db.create(Address(), pk: "addressId", auto: false, indexes:[])
        db.create(Transfer(), pk: "id", auto: true, indexes:[])
        db.create(Ledger(), pk: "id", auto: true, indexes:["address"])
        db.create(Spent(), pk: "id", auto: true, indexes:["address", "transferRef"])
        
        pw = password
        
        Execute.backgroundAfter(after: 2.0) {
            self.pollForChanges()
        }
        
    }
    
    func addExistingAddress(_ uuid: String) throws -> String {
        
        var encSeed: String?
        
        do {
            let aes = try AES(key: Data(bytes: pw.bytes.sha512()).prefix(32).bytes, blockMode: CBC(iv: Data(bytes:pw.bytes.sha512().sha512()).prefix(16).bytes), padding: Padding.pkcs7)
            
            encSeed = try aes.encrypt(uuid.data(using: String.Encoding.ascii)!.bytes).base58EncodedString
            
        } catch {
            
            throw WalletErrors.UnableToEncrypt
            
        }
        
        var oldMethod = false;
        if uuid.count < 36 {
            throw WalletErrors.InvalidSeed
        }
        
        if uuid.count == 36 {
            oldMethod = true
        }
        
        var seed: [UInt8] = []
        if oldMethod {
            seed = uuid.sha224().data(using: String.Encoding.ascii)!.prefix(upTo: 32).bytes
        } else {
            seed = Data(bytes:uuid.bytes.sha512()).prefix(32).bytes
        }
        let k = Keys(seed)
        
        walletLock.mutex {
            _ = db.execute(sql: "INSERT OR REPLACE INTO address (addressId,seed,height,name) VALUES (?,?,?,?);", params:[k.address(), encSeed!, 0, k.address()])
            
            // reset the wallets
            log.log(level: .Warning, log: "Address added, re-syncing wallet with network.")
            setHeight(0)
            
            addressCache = nil
        }
        
        return k.address()
        
    }
    
    func setHeight(_ height: Int) {

        walletLock.mutex {
            _ = db.execute(sql: "UPDATE Address SET height = ?", params: [height])
            if height == 0 {
                _ = db.execute(sql: "DELETE FROM Transfer", params: [])
                _ = db.execute(sql: "DELETE FROM Ledger", params: [])
                _ = db.execute(sql: "DELETE FROM Spent", params: [])
            }
        }

    }
    
    func height() -> Int {
        
        var retvalue = 0
        
        walletLock.mutex {
            let results = db.query(sql: "SELECT MIN(height) as lowest FROM Address", params: [])
            if results.error == nil && results.results.count > 0 {
                
                for r in results.results {
                    retvalue = r["lowest"]!.asInt() ?? 0
                    break
                }
                
            }
            
        }
        
        return retvalue
        
    }
    
    func isDecodable() -> Bool {
        for a in self.addresses() {
            if seedForAddress(a) == nil {
                return false
            }
        }
        return true
    }
    
    func createNewAddress() throws -> String {
        
        let uuid = UUID().uuidString.lowercased() + "-" + UUID().uuidString.lowercased()
        
        var encSeed: String?
        
        do {
            let aes = try AES(key: Data(bytes: pw.bytes.sha512()).prefix(32).bytes, blockMode: CBC(iv: Data(bytes:pw.bytes.sha512().sha512()).prefix(16).bytes), padding: Padding.pkcs7)
            
            encSeed = try aes.encrypt(uuid.data(using: String.Encoding.ascii)!.bytes).base58EncodedString
            
        } catch {
            
            throw  WalletErrors.UnableToEncrypt
            
        }
        
        let seed = Data(bytes:uuid.bytes.sha512()).prefix(32).bytes
        let k = Keys(seed)
        
        walletLock.mutex {
            
            _ = db.execute(sql: "INSERT OR REPLACE INTO address (addressId,seed,height,name) VALUES (?,?,?,?);", params:[k.address(), encSeed!, 0,k.address()])
            
            // reset the wallets
            log.log(level: .Warning, log: "Address created, re-syncing wallet with network.")
            setHeight(0)
            
        }
        
        return k.address()
        
    }
    
    func deleteAddress(_ address: String) {
        
        log.log(level: .Warning, log: "Address removed, re-syncing wallet with network.")
        
        walletLock.mutex {
            _ = db.execute(sql: "DELETE FROM Address WHERE addressId = ?;", params: [address])
            addressCache = nil
        }
        setHeight(0)
        
    }
    
    func nameAddress(_ address: String, name: String) {
        
        walletLock.mutex {
            _ = db.execute(sql: "UPDATE Address SET name = ? WHERE addressId = ?;", params: [name, address])
        }
        
    }
    
    func addresses() -> [String] {
        
        if addressCache != nil {
            return addressCache!
        }
        
        var retValue: [String] = []
        
        walletLock.mutex {
            
            let results = db.query(sql: "SELECT addressId FROM address", params: [])
            if results.error == nil && results.results.count > 0 {
                
                for r in results.results {
                    retValue.append(r["addressId"]!.asString()!)
                }
                
            }
            
            addressCache = retValue
            
        }
        
        return retValue
        
    }
    
    func addressesBytes() -> [Data] {
        
        var retValue: [Data] = []
        
        walletLock.mutex {
            let results = db.query(sql: "SELECT addressId FROM address", params: [])
            if results.error == nil && results.results.count > 0 {
                
                for r in results.results {
                    retValue.append(Crypto.strAddressToData(address: r["addressId"]!.asString()!))
                }
                
            }
        }
        
        return retValue
        
    }
    
    func seedForAddress(_ address: String) -> String? {
        
        var retValue: String? = nil
        
        walletLock.mutex {
            let results = db.query(sql: "SELECT seed FROM address WHERE addressId = ?", params: [address])
            if results.error == nil && results.results.count > 0 {
                
                for r in results.results {
                    
                    let seed = r["seed"]!.asString()!
                    do {
                        
                        // this is where we check for the old format file & old AES implementation.  It's upgraded on write out.
                        let encryptedData = seed.base58DecodedData
                        let aes = try AES(key: Data(bytes: pw.bytes.sha512()).prefix(32).bytes, blockMode: CBC(iv: Data(bytes:pw.bytes.sha512().sha512()).prefix(16).bytes), padding: Padding.pkcs7)
                        let decryptedSeed = String(bytes: try aes.decrypt(Array(encryptedData!)), encoding: .ascii)
                        if decryptedSeed!.contains("-") {
                            retValue = decryptedSeed
                        } else {
                            retValue = nil
                            break
                        }
                        
                    } catch  {
                        
                    }
                    
                }
                
            }
        }
        
        return retValue
        
    }
    
    func seedData() -> [Data:Data] {
        
        var d: [Data:Data] = [:]
        
        walletLock.mutex {
            let results = db.query(sql: "SELECT addressId,seed FROM Address;", params: [])
            if results.error == nil && results.results.count > 0 {
                
                for r in results.results {
                    
                    let seed = r["seed"]!.asString()!
                    let address = Crypto.strAddressToData(address: r["addressId"]!.asString()!)
                    do {
                        
                        // this is where we check for the old format file & old AES implementation.  It's upgraded on write out.
                        let encryptedData = seed.base58DecodedData
                        let aes = try AES(key: Data(bytes: pw.bytes.sha512()).prefix(32).bytes, blockMode: CBC(iv: Data(bytes:pw.bytes.sha512().sha512()).prefix(16).bytes), padding: Padding.pkcs7)
                        let decryptedSeed = String(bytes: try aes.decrypt(Array(encryptedData!)), encoding: .ascii)
                        
                        d[address] = Data((decryptedSeed!.bytes.sha512()).prefix(32))
                        
                    } catch  {
                        
                    }
                    
                }
                
            }
        }
        
        return d
        
    }
    
    func setNameForAddress(_ address: String, name: String) {
        walletLock.mutex {
            _ = db.execute(sql: "UPDATE address SET name = ? WHERE addressId = ?", params: [name, address])
        }
    }
    
    func nameForAddress(_ address: String) -> String? {

        var retValue: String? = nil
        
        walletLock.mutex {
            
            let results = db.query(sql: "SELECT name FROM Address WHERE addressId = ?", params: [address])
            if results.error == nil && results.results.count > 0 {
                
                for r in results.results {
                    retValue = r["name"]!.asString()!
                    break
                }
                
            }
            
        }
        
        return retValue
        
    }
    
    func addRemoveTokens(_ tokens: [Ledger], height: Int) {
        
        let aBytes = addressesBytes();
        
        walletLock.mutex {
            
            _ = db.execute(sql: "BEGIN TRANSACTION", params: [])
            
            for token in tokens {
                
                if !aBytes.contains(token.destination!) {
                    if aBytes.contains(token.source!) {
                        _ = db.execute(sql: "DELETE FROM Ledger WHERE address = ? AND ore = ?", params: [token.address!, token.ore!])
                    }
                } else {
                    _ = db.put(token)
                }
                
            }
            
            addTransferRecordsFromLedgers(tokens, height: height)
            
            _ = db.execute(sql: "COMMIT TRANSACTION", params: [])
            
        }
        
    }
    
    func balance(address: Data) -> Double {
        
        var retValue = 0.0
        
        walletLock.mutex {
            
            let results = db.query(sql: "SELECT SUM(value) as totalValue FROM Ledger WHERE destination = ? AND id NOT IN (SELECT id FROM Spent)", params:[address])
            if results.error == nil && results.results.count > 0 {
                for r in results.results {
                    retValue = Double((r["totalValue"]!.asInt() ?? 0) / Config.DenominationDivider)
                    break;
                }
            }
            
        }
        
        return retValue
        
    }
    
    func getHoldings(address: Data) -> [Int:Int] {
        
        var retValue: [Int:Int] = [:]
        
        walletLock.mutex {
            
            let current_denominations = db.query(sql: "SELECT COUNT(*) as total,value FROM Ledger WHERE id NOT IN (SELECT id FROM Spent) AND destination = ? GROUP BY value", params: [address])
            for r in current_denominations.results {
                let total = r["total"]!.asInt()!
                let value = r["value"]!.asInt()!
                retValue[value] = total
            }
            
        }
        
        return retValue
        
    }
    
    func pickTokenForExchange(_ value: Int, address: Data) -> (tokens:[Ledger], fee:[Ledger]) {
        
        var retValue: (tokens:[Ledger], fee:[Ledger]) = ([],[])
        
        walletLock.mutex {
            
            let token = db.query(Ledger(), sql: "SELECT * FROM Ledger WHERE id NOT IN (SELECT id FROM Spent) AND destination = ? AND value = ?", params: [address, value])
            if token.count > 0 {
                
                retValue = ([token[0]],[])
                
            }
            
        }
        
        return retValue
        
    }
    
    func suitableArrayOfTokensForValue(_ value: Int, networkFee: Int, address: Data) -> (tokens:[Ledger], fee:[Ledger]) {
        
        var returnTokens:(tokens:[Ledger],fee:[Ledger]) = ([],[])
        
        walletLock.mutex {
            
            let current_denominations = db.query(sql: "SELECT id,value FROM Ledger WHERE id NOT IN (SELECT id FROM Spent) AND destination = ?", params: [address])
            var denominations: [(id:Int,value:Int)] = []
            for r in current_denominations.results {
                let id = r["id"]!.asInt()!
                let value = r["value"]!.asInt()!
                denominations.append((id,value))
            }
            
            var attempts = 50
            while true {
                
                // repeatedly shuffle until a payment combo appears
                denominations.shuffle()
                returnTokens = ([],[])
                var used: [Int] = []
                
                // now we want to randomly select tokens from the available stock
                var remaining = value
                var remainingFee = networkFee
                
                for t in denominations {
                    
                    if !used.contains(t.id) {
                        
                        if t.value <= remaining || t.value <= remainingFee {
                            
                            if t.value <= remainingFee {
                                
                                let token = db.query(Ledger(), sql: "SELECT * FROM Ledger WHERE id = ?", params: [t.id])
                                if token.count > 0 {
                                    returnTokens.fee.append(token[0])
                                    remainingFee -= t.value
                                    used.append(t.id)
                                }
                                
                            } else if t.value <= remaining {
                                
                                let token = db.query(Ledger(), sql: "SELECT * FROM Ledger WHERE id = ?", params: [t.id])
                                if token.count > 0 {
                                    returnTokens.tokens.append(token[0])
                                    remaining -= t.value
                                    used.append(t.id)
                                }
                                
                            }
                            
                        }
                        
                        if remaining == 0 && remainingFee == 0 {
                            break
                        }
                        
                    }
                    
                }
                
                if remaining == 0 && remainingFee == 0 {
                    break
                }
                
                attempts -= 1
                
                if attempts == 0 {
                    
                    // work out if we were just simply unable to make the network fee because we don't have a token small enough
                    if remaining == 0 && remainingFee != 0 {
                        // work through the list, and try and find the smallest oversized token
                        
                        var selectedToken: (id:Int,value:Int)?
                        
                        for t in denominations {
                            if !used.contains(t.id) {
                                if t.value >= remainingFee {
                                    if selectedToken == nil || selectedToken!.value > t.value {
                                        selectedToken = t
                                    }
                                }
                            }
                        }
                        
                        if selectedToken != nil {
                            
                            // we found the smallest "over" fee payment
                            let token = db.query(Ledger(), sql: "SELECT * FROM Ledger WHERE id = ?", params: [selectedToken!.id])
                            if token.count > 0 {
                                returnTokens.tokens.append(token[0])
                                remaining -= selectedToken!.value
                                used.append(selectedToken!.id)
                            }
                            
                        } else {
                            
                            // return nothing
                            returnTokens = ([],[])
                            
                        }
                    }
                    
                    break
                }
                
            }
            
        }
        
        return returnTokens
        
    }
    
    func generateTransfer(distribution: (tokens:[Ledger], fee:[Ledger]),source: Data, destination: Data, ref: Data) -> TransferRequest {
        
        let sd = seedData()
        
        let t = TransferRequest()
        var tokensArr: [Ledger] = []
        var feeArr: [Ledger] = []
        
        for l in distribution.tokens {
            l.transaction_id = Data(bytes:UUID().uuidString.sha512().bytes.sha224())
            l.transaction_ref = ref
            l.source = source
            l.destination = destination
            l.op = LedgerOPType.ChangeOwner.rawValue
            l.hash = l.signatureHash()
            tokensArr.append(l)
        }
        for l in distribution.fee {
            
            l.transaction_ref = ref
            l.transaction_id = Data(bytes:UUID().uuidString.sha512().bytes.sha224())
            if Config.CommunityAddress != nil {
                l.destination = Crypto.strAddressToData(address: Config.CommunityAddress!)
                l.source = source
                l.op = LedgerOPType.ChangeOwner.rawValue
                l.hash = l.signatureHash()
                feeArr.append(l)
            }
            
        }
        
        t.tokens = Crypto.sign(seed: sd[distribution.tokens[0].source!]!, ledgers: tokensArr)
        t.fee = Crypto.sign(seed: sd[distribution.tokens[0].source!]!, ledgers: feeArr)
        
        return t
        
    }
    
    func spend(distribution: (tokens:[Ledger], fee:[Ledger])) {
        
        walletLock.mutex {
            
            for d in distribution.tokens {
                
                let s = Spent()
                s.id = d.id
                s.transferRef = d.transaction_ref
                _ = db.put(s)
                
            }
            
            for d in distribution.fee {
                
                let s = Spent()
                s.id = d.id
                s.transferRef = d.transaction_ref
                _ = db.put(s)
                
            }
            
        }
        
    }
    
    func getTransfers(wallet: Data) -> [Transfer] {
        
        var tfrs: [Data:Int] = [:]
        var timestamps: [Data:UInt64] = [:]
        var target: [Data:String] = [:]
        var heights: [Data:Int] = [:]
        
        walletLock.mutex {
            for l in db.query(Ledger(), sql: "SELECT * FROM Ledger WHERE (destination != source) AND (destination = ? OR source = ?)", params: [wallet,wallet]) {
                if l.source! == wallet {
                    
                    // this is a transfer out
                    if tfrs[l.transaction_ref!] == nil {
                        tfrs[l.transaction_ref!] = 0
                        timestamps[l.transaction_ref!] = l.date
                        target[l.transaction_ref!] = Crypto.dataAddressToStr(address: l.destination!)
                        heights[l.transaction_ref!] = l.height!
                    }
                    tfrs[l.transaction_ref!]! -= l.value!
                    
                } else {
                    
                    // this is a transfer in, but not a generated token or a re-spend
                    if l.transaction_ref == nil {
                        l.transaction_ref = l.transaction_id
                    }
                    
                    if tfrs[l.transaction_ref!] == nil {
                        tfrs[l.transaction_ref!] = 0
                        timestamps[l.transaction_ref!] = l.date
                        target[l.transaction_ref!] = Crypto.dataAddressToStr(address: l.destination!)
                        heights[l.transaction_ref!] = l.height!
                    }
                    tfrs[l.transaction_ref!]! += l.value!
                    
                }
            }
        }
        
        // now write these transfers into the transfer table
        if tfrs.keys.count > 0 {
            
            var transfers: [Transfer] = []
            
            walletLock.mutex {
                
                for tfr in tfrs {
                    
                    let t = Transfer()
                    t.height = heights[tfr.key]
                    t.timestamp = Int(timestamps[tfr.key]!)
                    t.tokenValue = tfr.value
                    t.transferRef = tfr.key
                    t.target = target[tfr.key]
                    transfers.append(t)
                    
                }
                
            }

            return transfers
            
        }
        
        return []
        
    }
    
    func confirmSpend(ref: Data) {
        
        walletLock.mutex {
            
            _ = db.execute(sql: "DELETE FROM Spent WHERE transferRef = ?", params: [ref])
            
        }
        
    }
    
    func addTransferRecordsFromLedgers(_ ledgers: [Ledger], height: Int) {
        
        var tfrs: [Data:Int] = [:]
        var timestamps: [Data:UInt64] = [:]
        var target: [Data:String] = [:]
        
        for l in ledgers {
            if addressesBytes().contains(l.source!) && !addressesBytes().contains(l.destination!) {
                // this is a transfer out
                if tfrs[l.transaction_ref!] == nil {
                    tfrs[l.transaction_ref!] = 0
                    timestamps[l.transaction_ref!] = l.date
                    target[l.transaction_ref!] = Crypto.dataAddressToStr(address: l.destination!)
                }
                tfrs[l.transaction_ref!]! -= l.value!
            } else if addressesBytes().contains(l.destination!) {
                
                // this is a transfer in, it could have no ref if it is a registration
                if l.transaction_ref == nil {
                    l.transaction_ref = l.transaction_id
                }
                
                if tfrs[l.transaction_ref!] == nil {
                    tfrs[l.transaction_ref!] = 0
                    timestamps[l.transaction_ref!] = l.date
                    target[l.transaction_ref!] = Crypto.dataAddressToStr(address: l.destination!)
                }
                tfrs[l.transaction_ref!]! += l.value!
            }
        }
        
        // now write these transfers into the transfer table
        if tfrs.keys.count > 0 {
            
            walletLock.mutex {
                
                for tfr in tfrs {
                    
                    let t = Transfer()
                    t.height = height
                    t.timestamp = Int(timestamps[tfr.key]!)
                    t.tokenValue = tfr.value
                    t.transferRef = tfr.key
                    t.target = target[tfr.key]
                    
                    let df = DateFormatter()
                    df.dateStyle = .medium
                    df.timeStyle = .medium
                    
                    if t.tokenValue! > 0 {
                        print("Incoming \(t.transferRef!.bytes.base58EncodedString) : \(df.string(from: Date(timeIntervalSince1970: Double(t.timestamp! / 1000)))) of \(Float(t.tokenValue!) / Float(Config.DenominationDivider)) \(Config.CurrencyName)".blue)
                    } else {
                        print("Outgoing \(t.transferRef!.bytes.base58EncodedString) : \(df.string(from: Date(timeIntervalSince1970: Double(t.timestamp! / 1000)))), of \(Float(t.tokenValue!) / Float(Config.DenominationDivider)) \(Config.CurrencyName) -> \(t.target!)".red)
                    }
                    
                    confirmSpend(ref: tfr.key)
                    
                }
                
            }
            
            print("\n")
            
        }
        
    }
    
    func pollForChanges() {
        
        var delay = 1.0
        
        if self.addresses().count > 0 {
            
            if wallet!.height() < Block.currentNetworkBlockHeight() {
                
                let nextHeight = wallet!.height() + 1
                
                let blockData = try? Data(contentsOf: URL(string:"http://\(node)/block?height=\(nextHeight)")!)
                if blockData != nil {
                    
                    let b = try? JSONDecoder().decode(Block.self, from: blockData!)
                    if b != nil {
                        
                        let block = b!
                        let adds = wallet!.addressesBytes()
                        var transactions: [Ledger] = []
                        
                        for l in block.transactions ?? [] {
                            if adds.contains(l.source!) || adds.contains(l.destination!) {
                                transactions.append(l)
                            }
                        }
                        
                        wallet!.addRemoveTokens(transactions, height: nextHeight)
                        
                        if block.height != nil {
                            wallet?.setHeight(Int(block.height!))
                        }
                        
                        log.log(level: .Info, log: "Downloaded block \(nextHeight) from node \(node)")
                        delay = 0.0
                        
                    } else {
                        
                        if Block.currentNetworkBlockHeight() - self.height() > 1 {
                            log.log(level: .Error, log: "Error downloading block \(nextHeight) from node \(node)")
                        }
                        
                        delay = 10.0
                        
                    }
                    
                } else {
                    
                    if Block.currentNetworkBlockHeight() - self.height() > 1 {
                        log.log(level: .Error, log: "Error downloading block \(nextHeight) from node \(node)")
                    }
                    
                    delay = 10.0
                    
                }
                
            } else {
                
                delay = 10.0
                
            }
            
        } else {
            
            delay = 10.0
            
        }
        
        Execute.backgroundAfter(after: delay) {
            self.pollForChanges()
        }
        
    }
    
}
