//    MIT License
//
//    Copyright (c) 2018 SharkChain Team
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
import SWSQLite
import VeldsparCore

let db = SWSQLite(path: "\(NSHomeDirectory())/.\(Config.CurrencyName)", filename: "\(Config.CurrencyName).db")

class Database {
    
    class func Initialize() {
        
        db.create(Block(), pk: "height", auto: false, indexes:[])
        db.create(Ledger(), pk: "id", auto: true, indexes:["address,ore","height"])
        //db.create(PeeringNode(), pk: "id", auto: true)
        
    }
    
    class func DeleteBlock(_ block: VeldsparCore.Block) -> Bool {
        
        if db.execute(sql: "DELETE FROM Block WHERE height = ?;", params: [block.height]).error != nil {
            return false
        }
        
        if db.execute(sql: "DELETE FROM Ledger WHERE height = ?;", params: [block.height]).error != nil {
            return false
        }
        
        return true
    }
    
    class func WriteLedger(_ ledger: Ledger) -> Bool {
        
        if db.put(ledger).error != nil {
            return false
        }
        
        return true
        
    }
    
    class func WriteBlock(_ block: Block) -> Bool {
        
        // TODO: transaction & rollback
        
        _ = db.execute(sql: "BEGIN TRANSACTION", params: [])
        if db.put(block).error == nil {
            
            // now write in the transactions into the table as well
            for ledger in block.transactions ?? [] {
                
                if WriteLedger(ledger) == false {
                    
                    _ = db.execute(sql: "ROLLBACK TRANSACTION;", params: [])
                    return false
                    
                }
                
            }
            _ = db.execute(sql: "COMMIT TRANSACTION;", params: [])
            return true
        }
        _ = db.execute(sql: "ROLLBACK TRANSACTION;", params: [])
        return false
        
    }
    
    class func SetTransactionStateForHeight(height: Int, state: LedgerTransactionState) {
        
        let result = db.query(sql: "UPDATE Ledger SET state = ? WHERE height = ?", params: [state.rawValue, height])
        if result.error != nil {
            return
        }
        
    }

    class func CurrentHeight() -> Int? {
        
        let result = db.query(sql: "SELECT height FROM Block ORDER BY height DESC LIMIT 1", params: [])
        if result.error != nil {
            return nil
        }
        
        if result.results.count > 0 {
            let r = result.results[0]
            return r["height"]!.asInt() ?? 0
        }
        
        return nil;
    }
    
    class func VerifyOwnership(tokens: [TransferToken], address: String) -> Bool {
        
        var retValue = true
        
        for t in tokens {
            
            let r = db.query(Ledger(), sql: "SELECT * FROM Ledger WHERE address = ? AND ore = ? ORDER BY date DESC LIMIT 1", params: [t.address!, t.ore!])
            
            // check for no-token
            if r.count == 0 {
                retValue = false
                break
            }
            
            // check for incorrect owner
            if r[0].destination! != Crypto.strAddressToData(address: address) {
                retValue = false
                break
            }
            
        }
        
        return retValue
        
    }
    
    class func CommitTransferToBlockchain(_ transfer: TransferRequest) -> Bool {
        
        
        return true
        
    }
    
    class func TokenOwnershipRecords(ore: Int, address: Data) -> [Ledger] {
    
        // get the last ten items, recent->oldest.  Uses status to determine pending and current.
        return db.query(Ledger(), sql: "SELECT * FROM Ledger WHERE ore = ? AND address = ? ORDER BY date DESC LIMIT 10", params: [ore, address])

    }
    
    class func BlockAtHeight(_ height: Int, includeTransactions: Bool) -> Block? {
        
        let blocks = db.query(Block(), sql: "SELECT * FROM Block WHERE height = ? LIMIT 1", params: [height])
        
        if blocks.count == 0 {
            return nil
        }
        
        var block = blocks.first!
        if includeTransactions {
            block.transactions = LedgersForHeight(height)
        } else {
            block.transactions = []
        }
        
        
        return block
        
    }
    
    class func LedgersForHeight(_ height: Int) -> [Ledger] {
        
        return db.query(Ledger(), sql: "SELECT * FROM Ledger WHERE height = ? ORDER BY address", params: [height])

    }
    
}
