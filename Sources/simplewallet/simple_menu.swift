//
//  simple_menu.swift
//  simplewallet
//
//  Created by Adrian Herridge on 04/08/2018.
//

import Foundation

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
