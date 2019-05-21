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
var wallet: WalletFile?
let walletLock = Mutex()
var node = "127.0.0.1:14242"
var isTestNet = false
let log = Logger()

// the choice switch

enum WalletAction {
    
    case ShowOptions
    case Open
    case Create
    case Transactions
    case Exit
    case Balance
    
}

//Method just to execute request, assuming the response type is string (and not file)
func HTTPsendRequest(request: URLRequest,
                     callback: @escaping (Error?, String?) -> Void) {
    let task = URLSession.shared.dataTask(with: request) { (data, res, err) in
        if (err != nil) {
            callback(err,nil)
        } else {
            callback(nil, String(data: data!, encoding: String.Encoding.utf8))
        }
    }
    task.resume()
}

// post JSON
func HTTPPostJSON(url: String,  data: Data,
                  callback: @escaping (Error?, String?) -> Void) {
    
    var request = URLRequest(url: URL(string: url)!)
    
    request.httpMethod = "POST"
    request.addValue("application/json",forHTTPHeaderField: "Content-Type")
    request.addValue("application/json",forHTTPHeaderField: "Accept")
    request.httpBody = data
    HTTPsendRequest(request: request, callback: callback)
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
        if arg.lowercased() == "--testnet" {
            isTestNet = true
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
        
        if arg.lowercased() == "--node" {
            
            if i+1 < args.count {
                
                let t = args[i+1]
                node = t
                
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
        let w =  WalletFile(currentFilename!, password: currentPassword!)
        if w.isDecodable() {
            
            wallet = w
            walletOpen = true
            print("")
            print("Wallet opened containing addresses:")
            for a in wallet!.addresses() {
                print(a)
            }
            
        } else {
            print("incorrect password")
            exit(0)
        }
        
    }
    
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
                    let w = WalletFile(filename!, password: password!)
                    if w.isDecodable() {
                        wallet = w
                        currentPassword = password
                        currentFilename = filename
                        walletOpen = true
                        print("")
                        print("Wallet opened containing addresses:")
                        for a in w.addresses() {
                            print(a)
                        }
                        
                        ShowOpenedMenu()
                        
                    } else {
                        print("incorrect password")
                        exit(0)
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
                    
                    wallet = WalletFile(filename!, password: password!)
                    let address = try? wallet!.createNewAddress()
                    currentFilename = filename
                    currentPassword = password
                    walletOpen = true
                    
                    print("")
                    print("Wallet created, please record the information below somewhere secure.")
                    
                    print("address: \(address ?? "")")
                    print("seed uuid: \(wallet!.seedForAddress(address!) ?? "")")
                    print("")
                    
                    ShowOpenedMenu()
                    
                }
                
            case "r":
                
                print("seed uuid ? (e.g. '82B27DE0-0FA8-4D86-9C7B-ACAA5424AC0F-82B27DE0-0FA8-4D86-9C7B-ACAA5424AC0F')")
                let uuid = readLine()
                if uuid == nil || uuid!.count < 36 {
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
                    
                    wallet = WalletFile(filename!, password: password!)
                    let address = try? wallet!.addExistingAddress(uuid!)
                    currentFilename = filename
                    currentPassword = password
                    walletOpen = true
                    
                    print("")
                    print("Wallet restored, please record the information below somewhere secure.")
                    
                    print("address: \(address ?? "")")
                    print("seed uuid: \(uuid!)")
                    print("")
                    
                    wallet!.Save()
                    
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
                print("Wallet balance(s)")
                print("--------------------------------------------------")
                print("Name                                   | Balance  ")
                print("--------------------------------------------------")
                
                for a in wallet!.addresses() {
                    var name = wallet!.nameForAddress(a)
                    if name != nil {
                        name! += "                                                     "
                    } else {
                        name = a
                    }
                    print("\(name!.prefix(36))" + "   " + "\(wallet!.balance(address: Crypto.strAddressToData(address: a)))")
                }
                print("")
                ShowOpenedMenu()
                
            case "l":
                
                var addStr: String? = nil
                
                if wallet!.addresses().count > 1 {
                    print("Wallets")
                    print("--------------------------------------------------")
                    print("Name                                   | Balance  ")
                    print("--------------------------------------------------")
                    
                    var idx = 1
                    var adds: [String] = []
                    for a in wallet!.addresses() {
                        var name = wallet!.nameForAddress(a)
                        if name != nil {
                            name! += "                                                     "
                        } else {
                            name = a
                        }
                        print("\(idx) \(name!.prefix(35))" + "    " + "\(wallet!.balance(address: Crypto.strAddressToData(address: a)))")
                        idx += 1
                        adds.append(a)
                    }
                    print("")
                    
                    print("select wallet to list transfers to/from:")
                    let selectedAddress = readLine()
                    if selectedAddress == nil || Int(selectedAddress!) == nil {
                        print("ERROR: invalid wallet")
                        break;
                    }
                    addStr = adds[Int(selectedAddress!)! - 1]
                } else {
                    addStr = wallet!.addresses()[0]
                }
                print("")
                
                let tfrs = wallet!.getTransfers(wallet: Crypto.strAddressToData(address: addStr!))
                
                for t in tfrs.incoming {
                    let df = DateFormatter()
                    df.dateStyle = .medium
                    df.timeStyle = .medium
                    
                    print("Incoming \(t.ref!.bytes.base58EncodedString) : \(df.string(from: Date(timeIntervalSince1970: Double(t.date! / 1000)))) of \(Float(t.total!) / Float(Config.DenominationDivider)) \(Config.CurrencyName)".blue)
        
                }
                
                for t in tfrs.outgoing {
                    let df = DateFormatter()
                    df.dateStyle = .medium
                    df.timeStyle = .medium
                    
                    print("Outgoing \(t.ref!.bytes.base58EncodedString) : \(df.string(from: Date(timeIntervalSince1970: Double(t.date! / 1000)))) of \(Float(t.total!) / Float(Config.DenominationDivider)) \(Config.CurrencyName)".blue)
                    
                }
                
                if tfrs.incoming.count == 0 && tfrs.outgoing.count == 0 {
                    print("No transfers found for this wallet address")
                }
                
                print("")
                
                ShowOpenedMenu()
                
            case "t":
                
                var addStr: String? = nil
                
                if wallet!.addresses().count > 1 {
                    print("Wallet balance(s)")
                    print("--------------------------------------------------")
                    print("Name                                   | Balance  ")
                    print("--------------------------------------------------")
                    
                    var idx = 1
                    var adds: [String] = []
                    for a in wallet!.addresses() {
                        var name = wallet!.nameForAddress(a)
                        if name != nil {
                            name! += "                                                     "
                        } else {
                            name = a
                        }
                        print("\(idx) \(name!.prefix(35))" + "    " + "\(wallet!.balance(address: Crypto.strAddressToData(address: a)))")
                        idx += 1
                        adds.append(a)
                    }
                    print("")
                    
                    print("select wallet to transfer from:")
                    var selectedAddress = readLine()
                    if selectedAddress == nil || Int(selectedAddress!) == nil {
                        print("ERROR: invalid wallet")
                        break;
                    }
                    addStr = adds[Int(selectedAddress!)! - 1]
                } else {
                    addStr = wallet!.addresses()[0]
                }
                
                // create a transfer object to transfer contents from this wallet to another wallet
                print("amount of \(Config.CurrencyNetworkAddress) to send to target? (e.g.) 10.00")
                let amount = readLine()
                if amount == nil || Float(amount!) == nil {
                    print("ERROR: invalid amount")
                    break;
                }
                
                let amt = Int(Float(amount!)!*Float(Config.DenominationDivider))
                if amt < 1 {
                    print("ERROR: invalid amount")
                    break;
                }
                
                if (Int(wallet?.balance(address: Crypto.strAddressToData(address: addStr!)) ?? 0) * Config.DenominationDivider) < (Config.NetworkFee + amt) {
                    print("ERROR: not enough in wallet to send total of \(Float((Config.NetworkFee + amt) / Config.DenominationDivider))")
                    break;
                }
                
                // create a transfer object to transfer contents from this wallet to another wallet
                print("destination address? (e.g. 'VEzTAJWTsPRN6XJJx8FQLqNE8YVi9jEARzyoQVR8Vcusk')")
                let dest = readLine()
                if dest == nil || dest!.count < 35 {
                    print("ERROR: invalid destination")
                    break;
                }
                
                print("payment reference [ENTER for default]? (e.g. 'INV-102332'.  Max 24 chars.)")
                var ref = readLine()
                if ref == nil || ref!.count < 1 {
                    ref = Data(UUID().uuidString.bytes.sha224()).prefix(24).bytes.base58EncodedString
                } else {
                    ref = ref?.prefix(24)
                }
                
                print("\nConfirmation:  You would like to create a transaction with the following properties:")
                print("-----------------------------------------------------------------------------------")
                print("Amount: \(Float(amt / Config.DenominationDivider) + Float(Config.NetworkFee / Config.DenominationDivider)) with a fee of \(Float(Config.NetworkFee / Config.DenominationDivider))")
                print("Destination: \(dest!)")
                print("Reference: \(ref)\n")
                
                print("do you wish to proceed? [Y/n]")
                var cont = readLine()
                if cont != nil {
                    if cont!.lowercased() == "n" {
                        break
                    }
                    else
                    {
                        // showtime, call the node and generate the transfer.
                        
                        
                        let items = wallet!.suitableArrayOfTokensForValue(amt, networkFee: Config.NetworkFee, address: Crypto.strAddressToData(address: addStr!))
                        if items.tokens.count == 0 || items.fee.count == 0 {
                            print("ERROR:  Unable to select the appropriate amount of tokens to make this transfer, please try again.")
                            break
                        }
                        let tfr = wallet!.generateTransfer(distribution: items,source: Crypto.strAddressToData(address: addStr!),destination: Crypto.strAddressToData(address: dest!), ref: ref.base58DecodedData!)
                        // now attempt to send this to the node for processing, then mark the transfer as Spent to avoid double spends
                        
                        
                        do {
                            let d = try JSONEncoder().encode(tfr)
                            HTTPPostJSON(url: "http://\(node)/transfer", data: d) { (err, result) in
                                if(err != nil) {
                                    
                                    print("ERROR: cound not send transfer to node, please check node is online and available.")
                                    
                                } else {
                            
                                    print("Transfer requested from network.")
                                    
                                }
                            }
                        } catch {
                            
                        }
                    }
                }
                
                ShowOpenedMenu()
                
                break
            case "h":
                
                var addStr: String? = nil
                
                if wallet!.addresses().count > 1 {
                    print("Wallet balance(s)")
                    print("--------------------------------------------------")
                    print("Name                                   | Balance  ")
                    print("--------------------------------------------------")
                    
                    var idx = 1
                    var adds: [String] = []
                    for a in wallet!.addresses() {
                        var name = wallet!.nameForAddress(a)
                        if name != nil {
                            name! += "                                                     "
                        }
                        print("\(idx) \(name!.prefix(35))" + "    " + "\(wallet!.balance(address: Crypto.strAddressToData(address: a)))")
                        idx += 1
                        adds.append(a)
                    }
                    print("")
                    
                    print("select wallet to show:")
                    var selectedAddress = readLine()
                    if selectedAddress == nil || Int(selectedAddress!) == nil {
                        print("ERROR: invalid wallet")
                        break;
                    }
                    addStr = adds[Int(selectedAddress!)! - 1]
                } else {
                    addStr = wallet!.addresses()[0]
                }
                
                // now get the breakdown
                let contents = wallet!.getHoldings(address: Crypto.strAddressToData(address: addStr!))
                print("Wallet holdings")
                print("---------------------")
                print("Token Value  | Total ")
                print("---------------------")
                print(" 50.00       | \(contents[5000] ?? 0)")
                print(" 20.00       | \(contents[2000] ?? 0)")
                print(" 10.00       | \(contents[1000] ?? 0)")
                print("  5.00       | \(contents[500] ?? 0)")
                print("  2.00       | \(contents[200] ?? 0)")
                print("  1.00       | \(contents[100] ?? 0)")
                print("  0.50       | \(contents[50] ?? 0)")
                print("  0.20       | \(contents[20] ?? 0)")
                print("  0.10       | \(contents[10] ?? 0)")
                print("  0.05       | \(contents[5] ?? 0)")
                print("  0.02       | \(contents[2] ?? 0)")
                print("  0.01       | \(contents[1] ?? 0)")
                
                ShowOpenedMenu()
                
                break
            case "c": // create new
                
                let uuid = UUID().uuidString.lowercased() + "-" + UUID().uuidString.lowercased()
                let address = try? wallet!.addExistingAddress(uuid)
                print("")
                print("Wallet created, please record the information below somewhere secure.")
                
                print("address: \(address ?? "")")
                print("seed uuid: \(uuid)")
                print("")
                
                ShowOpenedMenu()
                
            case "a": // add existing
                
                print("seed uuid ? (e.g. '82B27DE0-0FA8-4D86-9C7B-ACAA5424AC0F-82B27DE0-0FA8-4D86-9C7B-ACAA5424AC0F')")
                let uuid = readLine()
                if uuid == nil || uuid!.count < 36 {
                    print("ERROR: invalid seed uuid")
                    break;
                }
                
                
                walletLock.mutex {
                    
                    let address = try? wallet!.addExistingAddress(uuid!)
                    
                    print("")
                    print("Wallet restored, please record the information below somewhere secure.")
                    
                    print("address: \(address ?? "")")
                    print("seed uuid: \(wallet?.seedForAddress(address!) ?? "")")
                    print("")
                    
                    ShowOpenedMenu()
                    
                }
                
            case "d": // delete
                
                print("Choose address to delete")
                ListWallets()
                
                let choice = readLine()
                if choice == nil {
                    ShowOpenedMenu()
                    break
                }
                
                if Int(choice!) == nil {
                    ShowOpenedMenu()
                    break
                }
                
                if Int(choice!)! > wallet!.addresses().count {
                    ShowOpenedMenu()
                    break
                }
                
                wallet?.deleteAddress(wallet!.addresses()[Int(choice!)!-1])
                ShowOpenedMenu()
                break
                
            case "w": // list wallets
                ListWallets()
            case "n": // name wallet
                
                print("Choose wallet to rename")
                ListWallets()
                
                let choice = readLine()
                if choice == nil {
                    ShowOpenedMenu()
                    break
                }
                
                if Int(choice!) == nil {
                    ShowOpenedMenu()
                    break
                }
                
                if Int(choice!)! > wallet!.addresses().count {
                    ShowOpenedMenu()
                    break
                }
                
                let w = wallet!.addresses()[Int(choice!)!-1]
                
                print("new name ?")
                
                let newName = readLine()
                if newName != nil && newName!.count > 0 {
                    wallet!.nameAddress(w, name: newName!)
                }
                
                ShowOpenedMenu()
                break
                
            case "x":
                print("saving wallet to disk")
                wallet!.Save()
                exit(0)
            case "s":
                walletLock.mutex {
                    
                    for w in wallet!.addresses() {
                        print("seed for address \(w) is \(wallet!.seedForAddress(w) ?? "")")
                    }
                    
                }
            case "help":
                ShowOpenedMenu()
            default:
                ShowOpenedMenu()
            }
            
        }
        
    }
    
}


