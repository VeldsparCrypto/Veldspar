//
//  simple_menu.swift
//  simplewallet
//
//  Created by Adrian Herridge on 04/08/2018.
//

import Foundation
import VeldsparCore

func SimpleMenu(_ options: [String:String]) {
    
    print("")
    print("Wallet Options")
    print("--------------")
    print("")
    
    for o in options {
        print("  [\(o.key.uppercased())] : \(o.value)")
    }
    print("")
    print("Please choose one of the above options :")
    
    
}

func ShowOpenedMenu() {
    SimpleMenu(["P" : "Show pending transactions",
                "L" : "List transfers",
                "B" : "Balance",
                "X" : "Exit",
                "T" : "Transfer \(Config.CurrencyName) to another address.",
        "S" : "Show seed",
        "R" : "Rebuild wallet",
        "C" : "Create new wallet",
        "A" : "Add existing wallet",
        "D" : "Delete wallet",
        "W" : "List wallets", "N" : "Name a wallet"])
}

func ListWallets() {
    
    print("")
    print("Wallet(s)")
    print("---------")
    print("")
    
    var i = 1
    for w in currentWallet!.wallets {
        if w.name != nil {
            print("  [\(i)] : \(w.name!) (\(w.address!))")
        } else {
            print("  [\(i)] : \(w.address!)")
        }
        
        i+=1
    }
    print("")
    
}
