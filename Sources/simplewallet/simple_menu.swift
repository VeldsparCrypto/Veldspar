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
    for w in wallet!.addresses() {
        if wallet!.nameForAddress(w) != w {
            print("  [\(i)] : \(wallet!.nameForAddress(w)) (\(w))")
        } else {
            print("  [\(i)] : \(w)")
        }
        
        i+=1
    }
    print("")
    
}
