//
//  view.swift
//  onlinewallet
//
//  Created by Adrian Herridge on 24/05/2019.
//

import Foundation
import VeldsparCore
import Swifter

extension Pages {
    
    static func View(_ request: HttpRequest) -> String {
        
        var formData: [String:String] = [:]
        for p in request.parseUrlencodedForm() {
            formData[p.0] = p.1
        }
        
        if formData["address"] == nil || formData["address"]!.count < "VEHjeJADBc9DV4vkKZXmq2kgyCvPzkG2LYvRz35Fwv53by".count {
            return Root("Invalid address")
        }
        
        let wallet = blockchain.WalletAddressContents(address: Crypto.strAddressToData(address: formData["address"]!))
        
        return CommonEmbedding([WalletSummary(wallet), WalletIncomingTransactions(wallet), WalletOutgoingTransactions(wallet), WalletLatestMining(wallet)])
        
    }
    
    static func WalletSummary(_ wallet: WalletAddress) -> String {
        
        return """
        <style type="text/css">
        .tg  {border-collapse:collapse;border-spacing:0;border-color:#93a1a1;margin:0px auto; width: 800px;}
        .tg td{font-family:Arial, sans-serif;font-size:14px;padding:10px 8px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;border-color:#93a1a1;color:#002b36;background-color:#fdf6e3;}
        .tg th{font-family:Arial, sans-serif;font-size:14px;font-weight:normal;padding:10px 8px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;border-color:#93a1a1;color:#fdf6e3;background-color:#657b83;}
        .tg .tg-ucgi{background-color:#3166ff;color:#ffffff;text-align:left;vertical-align:top}
        .tg .tg-alz1{background-color:#eee8d5;text-align:left;vertical-align:top}
        .tg .tg-b4k6{background-color:#eee8d5;text-align:left}
        .tg .tg-0lax{text-align:left;vertical-align:top}
        </style>
        <table class="tg">
        <tr>
        <th class="tg-ucgi" colspan="2">Properties</th>
        </tr>
        <tr>
        <td class="tg-b4k6">Address:</td>
        <td class="tg-alz1">\(Crypto.dataAddressToStr(address: wallet.address!))</td>
        </tr>
        <tr>
        <td class="tg-0lax">Alias(s)</td>
        <td class="tg-0lax">None</td>
        </tr>
        <tr>
        <td class="tg-alz1">Balance:</td>
        <td class="tg-alz1">\(Float(wallet.current_balance!) / Float(Config.DenominationDivider)) \(Config.CurrencyNetworkAddress)</td>
        </tr>
        <tr>
        <td class="tg-0lax">Pending:</td>
        <td class="tg-0lax">\(Float(wallet.pending_balance!) / Float(Config.DenominationDivider)) \(Config.CurrencyNetworkAddress)</td>
        </tr>
        </table>
        """
        
    }
    
    static func WalletIncomingTransactions(_ wallet: WalletAddress) -> String {
        
        var incoming = ""
        
        for t in wallet.incoming {
            incoming += """
            <tr>
            <td class="tg-0lax">\(Date(timeIntervalSince1970: Double(t.date! / 1000)))</td>
            <td class="tg-0lax">\(Crypto.dataAddressToStr(address: t.source!))</td>
            <td class="tg-0lax">\(Float(t.total!) / Float(Config.DenominationDivider))</td>
            </tr>
            """
        }
        
        return """
        </br>
        <table class="tg">
        <tr>
        <th class="tg-ucgi" colspan="3">Incoming Transactions</th>
        </tr>
        <tr>
        <td class="tg-alz1">Date</td>
        <td class="tg-alz1">Source</td>
        <td class="tg-alz1">Amount</td>
        </tr>
        \(incoming)
        </table>
        """
        
    }
    
    static func WalletOutgoingTransactions(_ wallet: WalletAddress) -> String {
        
        var incoming = ""
        
        for t in wallet.outgoing {
            incoming += """
            <tr>
            <td class="tg-0lax">\(Date(timeIntervalSince1970: Double(t.date! / 1000)))</td>
            <td class="tg-0lax">\(Crypto.dataAddressToStr(address: t.destination!))</td>
            <td class="tg-0lax">\(Float(t.total!) / Float(Config.DenominationDivider))</td>
            </tr>
            """
        }
        
        return """
        </br>
        <table class="tg">
        <tr>
        <th class="tg-ucgi" colspan="3">Outgoing Transactions</th>
        </tr>
        <tr>
        <td class="tg-alz1">Date</td>
        <td class="tg-alz1">Destination</td>
        <td class="tg-alz1">Amount</td>
        </tr>
        \(incoming)
        </table>
        """
        
    }
    
    static func WalletLatestMining(_ wallet: WalletAddress) -> String {
        
        var incoming = ""
        
        for t in wallet.mining {
            incoming += """
            <tr>
            <td class="tg-0lax">\(Date(timeIntervalSince1970: Double(t.date! / 1000)))</td>
            <td class="tg-0lax">\(Float(t.value!) / Float(Config.DenominationDivider))</td>
            </tr>
            """
        }
        
        return """
        </br>
        <table class="tg">
        <tr>
        <th class="tg-ucgi" colspan="3">Recent mining activity</th>
        </tr>
        <tr>
        <td class="tg-alz1">Date</td>
        <td class="tg-alz1">Amount</td>
        </tr>
        \(incoming)
        </table>
        """
        
    }
    
}
