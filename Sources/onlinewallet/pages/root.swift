//
//  root.swift
//  onlinewallet
//
//  Created by Adrian Herridge on 24/05/2019.
//

import Foundation
import VeldsparCore

class Pages {
    
    static func Root(_ message: String?) -> String {
        
        return CommonEmbedding("""
            <h1>\(Config.CurrencyName) Online Wallet</h1>
            <p>Enter your wallet address for read only access to your wallet data.</p>
            </br>
            </br>
            \(message ?? "")
            </br>
            <form action="/view" method="POST">
                Wallet address:<br>
            <input type="text" name="address" value="" style="width: 400px"><br><br>
                <input type="submit" value="Show">
            </form>
""")
        
    }
    
}
