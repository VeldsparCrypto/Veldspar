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

class RPCSyncWallet {
    
    class func action(address: String, height: Int) -> RPC_Wallet_Sync_Object {
        
        let rpcBlock = RPC_Wallet_Sync_Object()
        
        let ledgers = blockchain.ledgersConcerningAddress(address, lastRowHeight: height)
        
        for row in ledgers {
            
            if row.0 > rpcBlock.rowid {
                rpcBlock.rowid = row.0
                
                let l = row.1
                
                let ledger = RPC_Ledger()
                ledger.block = l.block
                ledger.date = l.date
                ledger.destination = l.destination
                ledger.op = l.op.rawValue
                ledger.spend_auth = l.spend_auth
                ledger.token = l.token
                ledger.transaction_group = l.transaction_group
                ledger.transaction_id = l.transaction_id
                
                rpcBlock.transactions.append(ledger)
                
            }
            
        }
        
        return rpcBlock
        
    }
    
}
