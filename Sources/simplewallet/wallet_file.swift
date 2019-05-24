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
            
            self.w?.wallets.append(newWallet)
            
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
            self.w?.wallets.append(newWallet)
            
            // reset the wallets
            log.log(level: .Warning, log: "Address created")
            
        }
        
        return k.address()
        
    }
    
    func deleteAddress(_ address: String) {
        
        log.log(level: .Warning, log: "Address removed")
        
        walletLock.mutex {
            
            var foundWallet: Int?
            for idx in 0...self.w!.wallets.count-1 {
                let wa = self.w!.wallets[idx]
                if Crypto.dataAddressToStr(address: wa.address!) == address {
                    foundWallet = idx
                    break
                }
            }
            
            if foundWallet != nil {
                self.w?.wallets.remove(at: foundWallet!)
            }
            
        }

        
    }
    
    func nameAddress(_ address: String, name: String) {
        
        walletLock.mutex {
            for wa in self.w?.wallets ?? [] {
                if Crypto.dataAddressToStr(address: wa.address!) == address {
                    wa.name = name
                }
            }
        }
        
    }
    
    func addresses() -> [String] {
        
        var retValue: [String] = []
        
        walletLock.mutex {
            for wa in self.w?.wallets ?? [] {
                retValue.append(Crypto.dataAddressToStr(address: wa.address!))
            }
        }
        
        return retValue
        
    }
    
    func addressesBytes() -> [Data] {
        
        var retValue: [Data] = []
        
        walletLock.mutex {
            for wa in self.w?.wallets ?? [] {
                retValue.append(wa.address!)
            }
        }
        
        return retValue
        
    }
    
    func seedForAddress(_ address: String) -> String? {
        
        var retValue: String? = nil
        
        walletLock.mutex {
            for wa in self.w?.wallets ?? [] {
                if Crypto.dataAddressToStr(address: wa.address!) == address {
                    // this is the one
                    do {
                        
                        // this is where we check for the old format file & old AES implementation.  It's upgraded on write out.
                        let encryptedData = wa.seed
                        let aes = try AES(key: Data(bytes: self.pw.bytes.sha512()).prefix(32).bytes, blockMode: CBC(iv: Data(bytes:self.pw.bytes.sha512().sha512()).prefix(16).bytes), padding: Padding.pkcs7)
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
            for wa in self.w?.wallets ?? [] {
                do {
                    
                    // this is where we check for the old format file & old AES implementation.  It's upgraded on write out.
                    let encryptedData = wa.seed
                    let aes = try AES(key: Data(bytes: self.pw.bytes.sha512()).prefix(32).bytes, blockMode: CBC(iv: Data(bytes:self.pw.bytes.sha512().sha512()).prefix(16).bytes), padding: Padding.pkcs7)
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
            for wa in self.w?.wallets ?? [] {
                if Crypto.dataAddressToStr(address: wa.address!) == address {
                    retValue = wa.name
                }
            }
        }
        
        return retValue
        
    }
    
    func balance(address: Data) -> Double {
        
        var retValue = 0.0
        
        walletLock.mutex {
            for wa in self.w?.wallets ?? [] {
                if wa.address == address {
                    retValue += Double(Double(wa.current_balance ?? 0) / Double(Config.DenominationDivider))
                }
            }
        }
        
        return retValue
        
    }
    
    func signTransfer(reqest: TransferRequest) {
        
        let sd = seedData()
        reqest.tokens = Crypto.sign(seed: sd[reqest.tokens[0].source!]!, ledgers: reqest.tokens)
        reqest.fee = Crypto.sign(seed: sd[reqest.fee[0].source!]!, ledgers: reqest.fee)
        
    }
    
    func getTransfers(wallet: Data) -> (incoming: [WalletTransfer], outgoing: [WalletTransfer]) {
        
        var retValue: (incoming: [WalletTransfer], outgoing: [WalletTransfer]) = ([],[])
        
        walletLock.mutex {
            for wa in self.w?.wallets ?? [] {
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
                        for wa in self.w?.wallets ?? [] {
                            if Crypto.dataAddressToStr(address: wa.address!) == a {
                                wa.current_balance = b!.current_balance
                                wa.incoming_pending = b!.incoming_pending
                                wa.outgoing_pending = b!.outgoing_pending
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

