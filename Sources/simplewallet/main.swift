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
import VeldsparCore
import Ed25519
import CryptoSwift

#if os(Linux)
srandom(UInt32(time(nil)))
#endif

// default values
var currentPassword: String?
var currentFilename: String?
var walletOpen = false
var currentWallet: WalletContainer?
let walletLock = Mutex()

// the choice switch

enum WalletAction {
    
    case ShowOptions
    case Open
    case Create
    case Transactions
    case Exit
    case Balance
    
}

var currentAction: WalletAction = .ShowOptions

let args: [String] = CommandLine.arguments

if args.count > 1 {
    for i in 1...args.count-1 {
        
        let arg = args[i]
        
        if arg.lowercased() == "--help" {
            print("\(Config.CurrencyName) - Wallet - v\(Config.Version)")
            print("-----   COMMANDS -------")
            print("--walletfile          : specifies the name of the wallet to open")
            print("--password            : the password to decrypt the wallet")
            print("--debug               : enables debugging output")
            print(" ")
            exit(0)
        }
        if arg.lowercased() == "--debug" {
            debug_on = true
        }
        if arg.lowercased() == "--walletfile" {
            
            if i+1 < args.count {
                
                let add = args[i+1]
                currentFilename = add
                
            }
            
        }
        
        if arg.lowercased() == "--password" {
            
            if i+1 < args.count {
                
                let t = args[i+1]
                currentPassword = t
                
            }
            
        }
        
    }
}

print("---------------------------")
print("\(Config.CurrencyName) Wallet v\(Config.Version)")
print("---------------------------")

if currentPassword != nil && currentFilename != nil {
    
    // now try and open/decrypt the wallet object
    walletLock.mutex {
        let w = WalletContainer.read(filename: currentFilename!, password: currentPassword!)
        if w != nil {
            currentWallet = w
            for wallet in currentWallet?.wallets ?? [] {
                if wallet.height == nil {
                    wallet.height = 0
                }
            }
            walletOpen = true
            print("")
            print("Wallet opened containing addresses:")
            for wallet in currentWallet?.wallets ?? [] {
                print(wallet.address!)
            }
            
        } else {
            print("incorrect password")
            exit(0)
        }
    }
    
}

func WalletLoop() {
    
    while true {
        
        // fetch the current height
        if walletOpen {
            
            for wallet in currentWallet!.wallets {
                
                var walletHeight: UInt32 = 0
                var address: String?
                
                walletLock.mutex {
                    walletHeight = wallet.height!
                    address = wallet.address!
                }
                
                // there are blocks to process so get the next one
                let nextBlockData = Comms.request(method: "wallet/sync", parameters: ["height" : "\(walletHeight)", "address" : address!])
                if nextBlockData != nil {
                    
                    var grouped: [String:[RPC_Ledger]] = [:]
                    
                    let b = try? JSONDecoder().decode(RPC_Wallet_Sync_Object.self, from: nextBlockData!)
                    if b != nil {
                        
                        if b!.transactions.count > 0 {
                            
                            var totalAdded: Int = 0
                            var totalSpent: Int = 0
                            
                            walletLock.mutex {
                                
                                // we actually don't care about the block, just the transactions
                                for l in b!.transactions {
                                    
                                    if l.destination! == address! {
                                        
                                        // this is for us so we can add it into the wallet
                                        let wt = WalletToken()
                                        wt.token = l.token
                                        wt.value = UInt32(Token.valueFromId(wt.token!))
                                        wallet.tokens[l.token!] = wt
                                        
                                        totalAdded += Int(wt.value!)
                                        
                                    } else {
                                        
                                        // is this a transfer out of a token which was owned by this wallet?
                                        if wallet.tokens[l.token!] != nil {
                                            
                                            let wt = wallet.tokens.removeValue(forKey: l.token!)
                                            
                                            // create a transaction record, for the wallet
                                            if grouped[l.transaction_group!] == nil {
                                                grouped[l.transaction_group!] = []
                                            }
                                            
                                            grouped[l.transaction_group!]!.append(l)
                                            
                                            totalSpent += Int(wt!.value!)
                                            
                                        }
                                        
                                        
                                    }
                                    
                                }
                                
                                // now write in any grouped ledgers as WalletTransaction objects
                                for t in grouped {
                                    
                                    let trans = WalletTransaction()
                                    trans.ref = t.key
                                    trans.date = t.value[0].date
                                    trans.destination = t.value[0].destination
                                    
                                    for l in t.value {
                                        trans.value += UInt32(Token.valueFromId(l.token!))
                                    }
                                    
                                    wallet.transactions.append(trans)
                                    
                                }
                                
                                wallet.height = UInt32(b!.rowid)
                                
                            }
                            
                            currentWallet!.write(filename: currentFilename!, password: currentPassword!)
                            
                            print("\((Float(totalAdded) / Float(Config.DenominationDivider))) \(Config.CurrencyName) added to wallet.")
                            print("Value of spent tokens: \((Float(totalSpent) / Float(Config.DenominationDivider)))")
                            print("--------------------------")
                            print("Current balance: \(wallet.balance())")
                            
                        } else {
                            
                            Thread.sleep(forTimeInterval: 10)
                            
                        }
                        
                    }
                }
                
            }
            
        }
        
    }
    
}

Execute.background {
    WalletLoop()
}

while true {
    
    while true {
        
        if walletOpen == false {
            
            SimpleMenu(["O" : "Open existing wallet", "N" : "Create new wallet","R" : "Restore wallet", "X" : "Exit"])
            let answer = readLine()
            switch answer?.lowercased() ?? "" {
            case "o":
                
                print("filename ? (e.g. 'mywallet')")
                let filename = readLine()
                if filename == nil || filename!.count < 1 {
                    print("ERROR: invalid filename")
                    break;
                }
                
                print("password ?")
                let password = readLine()
                if password == nil || password!.count < 1 {
                    print("ERROR: invalid password")
                    break;
                }
                
                // now try and open/decrypt the wallet object
                walletLock.mutex {
                    let w = WalletContainer.read(filename: filename!, password: password!)
                    if w != nil {
                        currentWallet = w
                        currentWallet = w
                        for wallet in currentWallet?.wallets ?? [] {
                            if wallet.height == nil {
                                wallet.height = 0
                            }
                        }
                        currentPassword = password
                        currentFilename = filename
                        walletOpen = true
                        print("")
                        print("Wallet opened containing addresses:")
                        for wallet in currentWallet?.wallets ?? [] {
                            print(wallet.address!)
                        }
                        
                        ShowOpenedMenu()
                        
                    } else {
                        print("incorrect password")
                    }
                }
                
            case "n":
                
                print("filename ? (e.g. 'mywallet')")
                let filename = readLine()
                if filename == nil || filename!.count < 1 {
                    print("ERROR: invalid filename")
                    break;
                }
                
                print("password ?")
                let password = readLine()
                if password == nil || password!.count < 1 {
                    print("ERROR: invalid password")
                    break;
                }
                
                print("confirm password ?")
                let password2 = readLine()
                if password2 == nil || password2!.count < 1 {
                    print("ERROR: invalid password")
                    break;
                }
                if password! != password2! {
                    print("ERROR: passwords did not match")
                    break;
                }
                
                walletLock.mutex {
                    
                    currentWallet = WalletContainer()
                    let newWallet = Wallet()
                    let uuid = UUID().uuidString.lowercased() + "-" + UUID().uuidString.lowercased()
                    let seed = Data(bytes:uuid.bytes.sha512()).prefix(32).bytes
                    let k = Keys(seed)
                    newWallet.address = k.address()
                    newWallet.seed = uuid
                    newWallet.height = 0
                    currentWallet!.wallets.append(newWallet)
                    currentWallet?.write(filename: filename!, password: password!)
                    currentFilename = filename
                    currentPassword = password
                    walletOpen = true
                    
                    print("")
                    print("Wallet created, please record the information below somewhere secure.")
                    
                    print("address: \(newWallet.address!)")
                    print("seed uuid: \(uuid)")
                    print("")
                    print("current balance: \(newWallet.balance())")
                    
                    ShowOpenedMenu()
                    
                }
                
            case "r":
                
                var oldMethod = false;
                
                print("seed uuid ? (e.g. '82B27DE0-0FA8-4D86-9C7B-ACAA5424AC0F-82B27DE0-0FA8-4D86-9C7B-ACAA5424AC0F')")
                let uuid = readLine()
                if uuid == nil || uuid!.count < 36 {
                    print("ERROR: invalid seed uuid")
                    break;
                }
                
                if uuid!.count == 36 {
                    oldMethod = true
                }
                
                print("filename ? (e.g. 'mywallet')")
                let filename = readLine()
                if filename == nil || filename!.count < 1 {
                    print("ERROR: invalid filename")
                    break;
                }
                
                print("password ?")
                let password = readLine()
                if password == nil || password!.count < 1 {
                    print("ERROR: invalid password")
                    break;
                }
                
                print("confirm password ?")
                let password2 = readLine()
                if password2 == nil || password2!.count < 1 {
                    print("ERROR: invalid password")
                    break;
                }
                if password! != password2! {
                    print("ERROR: passwords did not match")
                    break;
                }
                
                walletLock.mutex {
                    
                    var seed: [UInt8] = []
                    currentWallet = WalletContainer()
                    let newWallet = Wallet()
                    if oldMethod {
                        seed = uuid!.sha224().data(using: String.Encoding.ascii)!.prefix(upTo: 32).bytes
                    } else {
                        seed = Data(bytes:uuid!.bytes.sha512()).prefix(32).bytes
                    }
                    
                    let k = Keys(seed)
                    newWallet.address = k.address()
                    newWallet.seed = uuid
                    newWallet.height = 0
                    currentWallet!.wallets.append(newWallet)
                    currentWallet?.write(filename: filename!, password: password!)
                    currentFilename = filename
                    currentPassword = password
                    walletOpen = true
                    
                    print("")
                    print("Wallet restored, please record the information below somewhere secure.")
                    
                    print("address: \(newWallet.address!)")
                    print("seed uuid: \(uuid!)")
                    print("")
                    print("current balance: \(newWallet.balance())")
                    
                    ShowOpenedMenu()
                    
                }
                
            case "x":
                exit(0)
            default:
                break;
            }
            
        } else {
            
            // wallet open
            
            let answer = readLine()
            switch answer?.lowercased() ?? "" {
            case "b":
                print("")
                print("current balance: \(currentWallet!.balance())")
            case "l":
                print("feature not implemented yet")
            case "p":
                print("feature not implemented yet")
            case "t":
                print("feature not implemented yet")
            case "c": // create new
                
                let newWallet = Wallet()
                let uuid = UUID().uuidString.lowercased() + "-" + UUID().uuidString.lowercased()
                let seed = Data(bytes:uuid.bytes.sha512()).prefix(32).bytes
                let k = Keys(seed)
                newWallet.address = k.address()
                newWallet.seed = uuid
                newWallet.height = 0
                currentWallet!.wallets.append(newWallet)
                currentWallet?.write(filename: currentFilename!, password: currentPassword!)
                print("")
                print("Wallet created, please record the information below somewhere secure.")
                
                print("address: \(newWallet.address!)")
                print("seed uuid: \(uuid)")
                print("")
                print("current balance: \(newWallet.balance())")
                
                ShowOpenedMenu()
                
            case "a": // add existing
                
                var oldMethod = false;
                
                print("seed uuid ? (e.g. '82B27DE0-0FA8-4D86-9C7B-ACAA5424AC0F-82B27DE0-0FA8-4D86-9C7B-ACAA5424AC0F')")
                let uuid = readLine()
                if uuid == nil || uuid!.count < 36 {
                    print("ERROR: invalid seed uuid")
                    break;
                }
                
                if uuid!.count == 36 {
                    oldMethod = true
                }
                
                
                walletLock.mutex {
                    
                    var seed: [UInt8] = []
                    let newWallet = Wallet()
                    if oldMethod {
                        seed = uuid!.sha224().data(using: String.Encoding.ascii)!.prefix(upTo: 32).bytes
                    } else {
                        seed = Data(bytes:uuid!.bytes.sha512()).prefix(32).bytes
                    }
                    
                    let k = Keys(seed)
                    newWallet.address = k.address()
                    newWallet.seed = uuid
                    newWallet.height = 0
                    currentWallet!.wallets.append(newWallet)
                    currentWallet?.write(filename: currentFilename!, password: currentPassword!)
                    walletOpen = true
                    
                    print("")
                    print("Wallet restored, please record the information below somewhere secure.")
                    
                    print("address: \(newWallet.address!)")
                    print("seed uuid: \(uuid!)")
                    print("")
                    print("current balance: \(newWallet.balance())")
                    
                    ShowOpenedMenu()
                    
                }
                
            case "d": // delete
                
                print("Choose wallet to delete")
                ListWallets()
                
                var choice = readLine()
                if choice == nil {
                    ShowOpenedMenu()
                    break
                }
                
                if Int(choice!) == nil {
                    ShowOpenedMenu()
                    break
                }
                
                if Int(choice!)! > currentWallet!.wallets.count {
                    ShowOpenedMenu()
                    break
                }
                
                currentWallet!.wallets.remove(at: Int(choice!)!-1)
                
                currentWallet?.write(filename: currentFilename!, password: currentPassword!)
                
                ShowOpenedMenu()
                break
                
            case "w": // list wallets
                ListWallets()
            case "n": // name wallet
                
                print("Choose wallet to rename")
                ListWallets()
                
                var choice = readLine()
                if choice == nil {
                    ShowOpenedMenu()
                    break
                }
                
                if Int(choice!) == nil {
                    ShowOpenedMenu()
                    break
                }
                
                if Int(choice!)! > currentWallet!.wallets.count {
                    ShowOpenedMenu()
                    break
                }
                
                let w = currentWallet!.wallets[Int(choice!)!-1]
                
                print("new name ?")
                
                let newName = readLine()
                if newName != nil && newName!.count > 0 {
                    w.name = newName
                }
                
                currentWallet?.write(filename: currentFilename!, password: currentPassword!)
                
                ShowOpenedMenu()
                break
                
            case "r":
                
                print("Rebuilding wallet, a full re-sync will now take place.")
                
                walletLock.mutex {
                    
                    for w in currentWallet!.wallets {
                        w.height = 0
                        w.tokens = [:]
                        w.transactions = []
                    }
                    
                    currentWallet?.write(filename: currentFilename!, password: currentPassword!)
                    
                }
                
            case "x":
                print("saving wallet")
                walletLock.mutex {
                    currentWallet!.write(filename: currentFilename!, password: currentPassword!)
                }
                exit(0)
            case "s":
                walletLock.mutex {
                    
                    for w in currentWallet!.wallets {
                        print("seed for address \(w.address!) is \(w.seed!)")
                    }
                    
                    
                }
            case "h":
                ShowOpenedMenu()
            case "help":
                ShowOpenedMenu()
            default:
                ShowOpenedMenu()
            }
            
        }
        
    }
    
}


