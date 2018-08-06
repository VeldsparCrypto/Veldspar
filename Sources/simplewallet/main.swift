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

#if os(Linux)
srandom(UInt32(time(nil)))
#endif

// default values
var currentPassword: String?
var currentFilename: String?
var currentSeed: String?
var walletOpen = false
var currentWallet: Wallet?
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
        let w = Wallet.read(filename: currentFilename!, password: currentPassword!)
        if w != nil {
            currentWallet = w
            if currentWallet!.height == nil {
                currentWallet!.height = 0
            }
            currentSeed = w?.seed
            walletOpen = true
            print("")
            print("Wallet opened:")
            print("address: \(currentWallet!.address!)")
        } else {
            print("incorrect password")
            exit(0)
        }
    }
    
}

func WalletLoop() {
    
    while true {
        
        var found = false
        
        // fetch the current height
        if walletOpen {
            
            let currentHeight = Comms.requestHeight()
            if currentHeight != nil {
                
                var walletHeight: UInt32 = 0
                var address: String?
                
                walletLock.mutex {
                    walletHeight = currentWallet!.height!
                    address = currentWallet!.address!
                }
                
                if currentHeight! > walletHeight {
                    
                    // there are blocks to process so get the next one
                    let nextBlockData = Comms.request(method: "blockchain/block", parameters: ["height" : "\(walletHeight+1)"])
                    if nextBlockData != nil {
                        
                        found = true
                        
                        var grouped: [String:[RPC_Ledger]] = [:]
                        
                        let b = try? JSONDecoder().decode(RPC_Block.self, from: nextBlockData!)
                        if b != nil {
                            
                            print("Processing block \(b!.height!) of \(currentHeight!)")
                            
                            walletLock.mutex {
                                
                                // we actually don't care about the block, just the transactions
                                for l in b!.transactions {
                                    
                                    if l.destination! == address! {
                                        
                                        // this is for us so we can add it into the wallet
                                        let wt = WalletToken()
                                        wt.token = l.token
                                        wt.value = UInt32(Token.valueFromId(wt.token!))
                                        currentWallet!.tokens[l.token!] = wt
                                        
                                        print("Incoming token added to your wallet with a value of \(Float(wt.value!) / Float(Config.DenominationDivider))")
                                        
                                    } else {
                                        
                                        // is this a transfer out of a token which was owned by this wallet?
                                        if currentWallet!.tokens[l.token!] != nil {
                                            
                                            currentWallet!.tokens.removeValue(forKey: l.token!)
                                            
                                            // create a transaction record, for the wallet
                                            if grouped[l.transaction_group!] == nil {
                                                grouped[l.transaction_group!] = []
                                            }
                                            
                                            grouped[l.transaction_group!]!.append(l)
                                            
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
                                    
                                    currentWallet!.transactions.append(trans)
                                    
                                }
                                
                                currentWallet!.height = b?.height
                                currentWallet!.write(filename: currentFilename!, password: currentPassword!)
                                
                            }
                            
                        }
                        
                        
                    }
                    
                }
                
            }
            
        }
        
        if !found {
            Thread.sleep(forTimeInterval: 10)
        }
        found = false
        
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
                    let w = Wallet.read(filename: filename!, password: password!)
                    if w != nil {
                        currentWallet = w
                        if currentWallet!.height == nil {
                            currentWallet!.height = 0
                        }
                        currentPassword = password
                        currentFilename = filename
                        currentSeed = w?.seed
                        walletOpen = true
                        print("")
                        print("Wallet opened:")
                        print("address: \(currentWallet!.address!)")
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
                    currentWallet = Wallet()
                    let uuid = UUID().uuidString.lowercased()
                    let seed = uuid.sha224().data(using: String.Encoding.ascii)!.prefix(upTo: 32).bytes
                    let k = Keys(seed)
                    currentWallet!.address = k.address()
                    currentWallet!.seed = uuid
                    currentWallet!.height = Comms.requestHeight() ?? 0
                    currentWallet?.write(filename: filename!, password: password!)
                    currentSeed = uuid
                    currentFilename = filename
                    currentPassword = password
                    walletOpen = true
                    
                    print("")
                    print("Wallet created, please record the information below somewhere secure.")
                    
                    print("address: \(currentWallet!.address!)")
                    print("seed uuid: \(uuid)")
                    print("")
                    print("current balance: \(currentWallet!.balance())")
                }
                
            case "r":
                print("seed uuid ? (e.g. '82B27DE0-0FA8-4D86-9C7B-ACAA5424AC0F')")
                let uuid = readLine()
                if uuid == nil || uuid!.count < 36 || uuid!.count > 36 {
                    print("ERROR: invalid seed uuid")
                    break;
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
                    currentWallet = Wallet()
                    let seed = uuid!.sha224().data(using: String.Encoding.ascii)!.prefix(upTo: 32).bytes
                    let k = Keys(seed)
                    currentWallet!.address = k.address()
                    currentWallet!.seed = uuid
                    currentWallet!.height = 0
                    currentWallet?.write(filename: filename!, password: password!)
                    currentSeed = uuid
                    currentFilename = filename
                    currentPassword = password
                    walletOpen = true
                    
                    print("")
                    print("Wallet created, please record the information below.")
                    print("address: \(currentWallet!.address!)")
                    print("")
                }
                
            case "x":
                exit(0)
            default:
                break;
            }
            
        } else {
            
            // wallet open
            SimpleMenu(["P" : "Show pending transactions", "L" : "List transfers","B" : "Balance", "X" : "Exit", "T" : "Transfer \(Config.CurrencyName) to another address.","S" : "Show seed", "R" : "Rebuild wallet"])
            
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
            case "r":
                
                print("Rebuilding wallet, a full re-sync wil now take place.")
                
                walletLock.mutex {
                    
                    currentWallet!.height = 0
                    currentWallet!.tokens = [:]
                    currentWallet!.transactions = []
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
                    print("seed uuid : \(currentWallet!.seed!)")
                }
            default:
                break
            }
            
        }
        
    }
    
}


