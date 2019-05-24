//
//  common.swift
//  onlinewallet
//
//  Created by Adrian Herridge on 24/05/2019.
//

import Foundation
import VeldsparCore

extension Pages {
    
    static func CommonEmbedding(_ sections: [String]) -> String {
        
        var concat = ""
        for s in sections {
            concat += "</br>\n"
            concat += s
        }
        
        return CommonEmbedding(concat)
        
    }
    
    static func CommonEmbedding(_ body: String) -> String {
        
        return """

        <!DOCTYPE html>
        <html>
        <head>
        <title>\(Config.CurrencyName) Online Wallet</title>
        <style>
        body {
        background-color: black;
        text-align: center;
        color: white;
        }
        </style>
        </head>
        <body>
        
        \(body)
        
        </body>
        </html>
        
        """
        
    }
    
}
