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

class WalletFile {
    
    private var pw: String
    private var file: String
    private var w: Wallet?
    
    init(_ walletFilePath: String, password: String) {
        
        let d = try? Data(contentsOf: URL(fileURLWithPath: walletFilePath))
        if d != nil {
            w = try? JSONDecoder().decode(Wallet.self, from: d!)
            if w == nil {
                log.log(level: .Error, log: "Unable to open wallet file")
                exit(1)
            }
            
        } else {
            w = Wallet()
        }
        
        file = walletFilePath
        pw = password
        
        Execute.backgroundAfter(after: 2.0) {
            self.pollForChanges()
        }
        
    }
    
    func Save() {
        
        let d = try? JSONEncoder().encode(w!)
        if d != nil {
            try? d?.write(to: URL(fileURLWithPath: file))
        }
        
    }
    
    func addExistingAddress(_ uuid: String) throws -> String {
        
        var encSeed: Data?
        
        do {
            let aes = try AES(key: Data(bytes: pw.bytes.sha512()).prefix(32).bytes, blockMode: CBC(iv: Data(bytes:pw.bytes.sha512().sha512()).prefix(16).bytes), padding: Padding.pkcs7)
            
            encSeed = try Data(aes.encrypt(uuid.data(using: String.Encoding.ascii)!.bytes))
            
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
            
            let newWallet = WalletAddress()
            newWallet.address = Crypto.strAddressToData(address: k.address())
            newWallet.height = 0
            newWallet.seed = encSeed
            
            w?.wallets.append(newWallet)
            
            log.log(level: .Warning, log: "Address added")
            
        }
        
        return k.address()
        
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
        
        var encSeed: Data?
        
        do {
            let aes = try AES(key: Data(bytes: pw.bytes.sha512()).prefix(32).bytes, blockMode: CBC(iv: Data(bytes:pw.bytes.sha512().sha512()).prefix(16).bytes), padding: Padding.pkcs7)
            
            encSeed = try Data(aes.encrypt(uuid.data(using: String.Encoding.ascii)!.bytes))
            
        } catch {
            
            throw  WalletErrors.UnableToEncrypt
            
        }
        
        let seed = Data(bytes:uuid.bytes.sha512()).prefix(32).bytes
        let k = Keys(seed)
        
        walletLock.mutex {
            
            let newWallet = WalletAddress()
            newWallet.address = Crypto.strAddressToData(address: k.address())
            newWallet.height = 0
            newWallet.seed = encSeed
            w?.wallets.append(newWallet)
            
            // reset the wallets
            log.log(level: .Warning, log: "Address created")
            
        }
        
        return k.address()
        
    }
    
    func deleteAddress(_ address: String) {
        
        log.log(level: .Warning, log: "Address removed")
        
        walletLock.mutex {
            
            var foundWallet: Int?
            for idx in 0...w!.wallets.count-1 {
                let wa = w!.wallets[idx]
                if Crypto.dataAddressToStr(address: wa.address!) == address {
                    foundWallet = idx
                    break
                }
            }
            
            if foundWallet != nil {
                w?.wallets.remove(at: foundWallet!)
            }
            
        }

        
    }
    
    func nameAddress(_ address: String, name: String) {
        
        walletLock.mutex {
            for wa in w?.wallets ?? [] {
                if Crypto.dataAddressToStr(address: wa.address!) == address {
                    wa.name = name
                }
            }
        }
        
    }
    
    func addresses() -> [String] {
        
        var retValue: [String] = []
        
        walletLock.mutex {
            for wa in w?.wallets ?? [] {
                retValue.append(Crypto.dataAddressToStr(address: wa.address!))
            }
        }
        
        return retValue
        
    }
    
    func addressesBytes() -> [Data] {
        
        var retValue: [Data] = []
        
        walletLock.mutex {
            for wa in w?.wallets ?? [] {
                retValue.append(wa.address!)
            }
        }
        
        return retValue
        
    }
    
    func seedForAddress(_ address: String) -> String? {
        
        var retValue: String? = nil
        
        walletLock.mutex {
            for wa in w?.wallets ?? [] {
                if Crypto.dataAddressToStr(address: wa.address!) == address {
                    // this is the one
                    do {
                        
                        // this is where we check for the old format file & old AES implementation.  It's upgraded on write out.
                        let encryptedData = wa.seed
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
            for wa in w?.wallets ?? [] {
                do {
                    
                    // this is where we check for the old format file & old AES implementation.  It's upgraded on write out.
                    let encryptedData = wa.seed
                    let aes = try AES(key: Data(bytes: pw.bytes.sha512()).prefix(32).bytes, blockMode: CBC(iv: Data(bytes:pw.bytes.sha512().sha512()).prefix(16).bytes), padding: Padding.pkcs7)
                    let decryptedSeed = try aes.decrypt(Array(encryptedData!))
                    let uuid = String(bytes: decryptedSeed, encoding: .ascii)!
                    var oldMethod = false
                    if uuid.count == 36 {
                        oldMethod = true
                    }
                    var seed: [UInt8] = []
                    if oldMethod {
                        seed = uuid.sha224().data(using: String.Encoding.ascii)!.prefix(upTo: 32).bytes
                    } else {
                        seed = Data(bytes:uuid.bytes.sha512()).prefix(32).bytes
                    }
                    d[wa.address!] = Data(bytes: seed)
                    
                } catch  {
                    
                }
            }
        }
        
        return d
        
    }
    
    func nameForAddress(_ address: String) -> String? {

        var retValue: String? = nil
        
        walletLock.mutex {
            for wa in w?.wallets ?? [] {
                if Crypto.dataAddressToStr(address: wa.address!) == address {
                    retValue = wa.name
                }
            }
        }
        
        return retValue
        
    }
    
    func setTokens(address: Data, current: [Ledger], incoming: [WalletTransfer], outgoing: [WalletTransfer]) {
        walletLock.mutex {
            for wa in w?.wallets ?? [] {
                if wa.address == address {
                    wa.current_tokens = current
                    wa.incoming = incoming
                    wa.outgoing = outgoing
                }
            }
        }
    }
    
    func balance(address: Data) -> Double {
        
        var retValue = 0.0
        
        walletLock.mutex {
            for wa in w?.wallets ?? [] {
                if wa.address == address {
                    for c in wa.current_tokens {
                        retValue += Double(Double(c.value ?? 0) / Double(Config.DenominationDivider))
                    }
                }
            }
        }
        
        return retValue
        
    }
    
    func getHoldings(address: Data) -> [Int:Int] {
        
        var retValue: [Int:Int] = [:]
        
        walletLock.mutex {
            for wa in w?.wallets ?? [] {
                if wa.address == address {
                    for c in wa.current_tokens {
                        if retValue[c.value!] == nil {
                            retValue[c.value!] = 1
                        } else {
                            retValue[c.value!]! += 1
                        }
                    }
                }
            }
        }
        
        return retValue
        
    }
    
    func suitableArrayOfTokensForValue(_ value: Int, networkFee: Int, address: Data) -> (tokens:[Ledger], fee:[Ledger]) {
        
        var returnTokens:(tokens:[Ledger],fee:[Ledger]) = ([],[])
        
        // as a suggestion from anemol (https://github.com/anemol), we will use the "Greedy Method"
        
        var leftToFind: Int = value
        var leftToFee: Int = networkFee
        
        walletLock.mutex {
            for wa in w?.wallets ?? [] {
                if wa.address == address {
                    
                    var tokens: [Ledger] = []
                    tokens.append(contentsOf: wa.current_tokens)
                    
                    while leftToFind > 0 {
                        var chosen: Ledger?
                        for c in tokens {
                            if c.value ?? 0 <= leftToFind {
                                if chosen == nil || chosen?.value ?? 0 < c.value ?? 0 {
                                    chosen = c
                                }
                            }
                        }
                        if chosen == nil {
                            
                            // nothing would fit, so escape
                            returnTokens.fee = []
                            returnTokens.tokens = []
                            break;
                            
                        } else {
                            
                            // value chosen, so add it to the array
                            returnTokens.tokens.append(chosen!)
                            
                            // remove it from the available list
                            var idx = 0
                            var match = 0
                            for l in tokens {
                                if l.id == chosen?.id {
                                    match = idx
                                    break
                                }
                                idx += 1
                            }
                            
                            if match > 0 {
                                tokens.remove(at: match)
                            }
                            
                            leftToFind -= chosen!.value!
                            
                            chosen = nil
                            
                        }
                    }
                    
                    
                    while leftToFee > 0 {
                        var chosen: Ledger?
                        for c in tokens {
                            if c.value ?? 0 <= leftToFee {
                                if chosen == nil || chosen?.value ?? 0 < c.value ?? 0 {
                                    chosen = c
                                }
                            }
                        }
                        if chosen == nil {
                            
                            // nothing would fit, so escape
                            returnTokens.fee = []
                            returnTokens.tokens = []
                            break;
                            
                        } else {
                            
                            // value chosen, so add it to the array
                            returnTokens.fee.append(chosen!)
                            
                            // remove it from the available list
                            var idx = 0
                            var match = 0
                            for l in tokens {
                                if l.id == chosen?.id {
                                    match = idx
                                    break
                                }
                                idx += 1
                            }
                            
                            if match > 0 {
                                tokens.remove(at: match)
                            }
                            
                            leftToFee -= chosen!.value!
                            
                            chosen = nil
                            
                        }
                    }
                    
                    wa.current_tokens = tokens
                    
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
    
    func getTransfers(wallet: Data) -> (incoming: [WalletTransfer], outgoing: [WalletTransfer]) {
        
        var retValue: (incoming: [WalletTransfer], outgoing: [WalletTransfer]) = ([],[])
        
        walletLock.mutex {
            for wa in w?.wallets ?? [] {
                if wa.address == wallet {
                    retValue.incoming = wa.incoming
                    retValue.outgoing = wa.outgoing
                }
            }
        }
        
        return retValue
        
    }
    
    func pollForChanges() {
        
        let delay = 180.0
        
        
        for a in addresses() {
            
            // fetch the wallet contents and overwrite the existing value
            let blockData = try? Data(contentsOf: URL(string:"http://\(node)/wallet?address=\(a)")!)
            if blockData != nil {
                
                let b = try? JSONDecoder().decode(WalletAddress.self, from: blockData!)
                if b != nil {
                    
                    walletLock.mutex {
                        for wa in w?.wallets ?? [] {
                            if Crypto.dataAddressToStr(address: wa.address!) == a {
                                wa.current_tokens = b!.current_tokens
                                wa.incoming = b!.incoming
                                wa.outgoing = b!.outgoing
                            }
                        }
                    }
                    
                } else {
                    print("error decoding response form server")
                }
            }
            
        }
    
        Execute.backgroundAfter(after: delay) {
            self.pollForChanges()
        }
    }
    
}

