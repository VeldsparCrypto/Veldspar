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

#if os(Linux)
let blockchain_db = SWSQLite(path: "\(NSHomeDirectory())/.\(Config.CurrencyName)", filename: "blockchain.db")
let pending_db = SWSQLite(path: "\(NSHomeDirectory())/.\(Config.CurrencyName)", filename: "pending.db")
#else
let blockchain_db = SWSQLite(path: "\(URL(fileURLWithPath: NSHomeDirectory())).\(Config.CurrencyName)", filename: "blockchain.db")
let pending_db = SWSQLite(path: "\(URL(fileURLWithPath: NSHomeDirectory())).\(Config.CurrencyName)", filename: "pending.db")
#endif

class Database {
    
    class func Initialize() {
        
        _ = blockchain_db.execute(sql: "CREATE TABLE IF NOT EXISTS block (height INTEGER PRIMARY KEY, hash TEXT, oreSeed TEXT, confirms INTEGER, shenanigans INTEGER)", params: [])
        _ = blockchain_db.execute(sql:
            """
CREATE TABLE IF NOT EXISTS ledger (
    transaction_id TEXT PRIMARY KEY,
    op INTEGER,
    date INTEGER,
    transaction_group TEXT,
    owner TEXT,
    token TEXT,
    spend_auth TEXT,
    block INTEGER,
    checksum TEXT
)
""", params: [])
        
        _ = pending_db.execute(sql:
            """
CREATE TABLE IF NOT EXISTS ledger (
    transaction_id TEXT PRIMARY KEY,
    op INTEGER,
    date INTEGER,
    transaction_group TEXT,
    owner TEXT,
    token TEXT,
    spend_auth TEXT,
    block INTEGER,
    checksum TEXT
)
""", params: [])
        
    }
    
    class func DeleteBlock(_ block: Block) -> Bool {
        
        if blockchain_db.execute(sql: "DELETE FROM block WHERE height = ?; DELETE FROM ledger WHERE block = ?;", params: [block.height, block.height]).error != nil {
            return false
        }
        
        return true
    }
    
    class func WritePendingLedger(_ ledger: Ledger) -> Bool {
        
        if pending_db.execute(
            sql: "INSERT OR REPLACE INTO ledger (transaction_id, op, date, transaction_group, owner, token, spend_auth, block, checksum) VALUES (?,?,?,?,?,?,?,?,?)",
            params: [
                
                ledger.transaction_id,
                ledger.op.rawValue,
                ledger.date,
                ledger.transaction_group,
                ledger.destination,
                ledger.token,
                ledger.spend_auth,
                ledger.block,
                ledger.checksum()
                
            ]).error != nil {
            return false
            
        }
        return true
        
    }
    
    class func WriteBlock(_ block: Block) -> Bool {
        
        // TODO: transaction & rollback
        
        if blockchain_db.execute(sql: "INSERT OR REPLACE INTO block (height, hash, oreSeed, confirms, shenanigans) VALUES (?,?,?,?,?)", params: [UInt64(block.height), block.hash!, block.oreSeed ?? NSNull(), block.confirms, block.shenanigans]).error == nil {
            
            // now write in the transactions into the table as well
            for t in block.transactions {
                if blockchain_db.execute(
                    sql: "INSERT OR REPLACE INTO ledger (transaction_id, op, date, transaction_group, owner, token, spend_auth, block, checksum) VALUES (?,?,?,?,?,?,?,?,?)",
                    params: [
                        
                        t.transaction_id,
                        UInt64(t.op.rawValue),
                        UInt64(t.date),
                        t.transaction_group,
                        t.destination,
                        t.token,
                        t.spend_auth,
                        UInt64(t.block),
                        t.checksum()
                        
                    ]).error != nil {
                    return false
                }
            }
            
            return true
        }
        
        return false
    }
    
    class func CurrentHeight() -> UInt32? {
        
        let result = blockchain_db.query(sql: "SELECT height FROM block ORDER BY height DESC LIMIT 1", params: [])
        if result.error != nil {
            return nil
        }
        
        if result.results.count > 0 {
            let r = result.results[0]
            return UInt32(r["height"]!.asUInt64()!)
        }
        
        return nil;
    }
    
    class func TokenOwnershipRecord(_ id: String) -> Ledger? {
        
        let result = blockchain_db.query(sql: "SELECT * FROM ledger WHERE token = ? ORDER BY block DESC LIMIT 1", params: [id])
        if result.error != nil {
            return nil
        }
        
        if result.results.count > 0 {
            let r = result.results[0]
            let l = Ledger(id: r["transaction_id"]!.asString()!,
                           op: LedgerOPType(rawValue: r["op"]!.asInt()!)!,
                           token: r["token"]!.asString()!,
                           ref: r["transaction_group"]!.asString()!,
                           address: r["owner"]!.asString()!,
                           date: r["date"]!.asUInt64()!,
                           auth: r["spend_auth"]!.asString()!,
                           block: UInt32(r["block"]!.asUInt64()!))
            return l
        }
        
        return nil;
    }
    
    class func TokenPendingRecord(_ id: String) -> Ledger? {
        
        let result = pending_db.query(sql: "SELECT * FROM ledger WHERE token = ? ORDER BY block DESC LIMIT 1", params: [id])
        if result.error != nil {
            return nil
        }
        
        if result.results.count > 0 {
            let r = result.results[0]
            let l = Ledger(id: r["transaction_id"]!.asString()!,
                           op: LedgerOPType(rawValue: r["op"]!.asInt()!)!,
                           token: r["token"]!.asString()!,
                           ref: r["transaction_group"]!.asString()!,
                           address: r["owner"]!.asString()!,
                           date: r["date"]!.asUInt64()!,
                           auth: r["spend_auth"]!.asString()!,
                           block: UInt32(r["block"]!.asUInt64()!))
            return l
        }
        
        return nil;
    }
    
    class func BlockAtHeight(_ height: UInt32) -> Block? {
        
        let result = blockchain_db.query(sql: "SELECT * FROM block WHERE height = ? LIMIT 1", params: [UInt64(height)])
        if result.error != nil {
            debug("(Database) 'BlockAtHeight(_ height: UInt32) -> Block?', received an Error from the SQLite database engine.  Error = '\(result.error!)'")
            return nil
        }
        
        if result.results.count > 0 {
            
            let br = result.results[0]
            let b = Block(height: height)
            b.oreSeed = br["oreSeed"]?.asString()
            b.hash = br["hash"]?.asString()
            b.confirms = br["confirms"]?.asUInt64() ?? 0
            b.shenanigans = br["shenanigans"]?.asUInt64() ?? 0
            
            // now get the transactions for that block
            let trans = blockchain_db.query(sql: "SELECT * FROM ledger WHERE block = ? ORDER BY token", params: [UInt64(height)])
            if trans.error != nil {
                return nil
            }
            
            if trans.results.count > 0 {
                
                for r in trans.results {
                    
                    let l = Ledger(id: r["transaction_id"]!.asString()!,
                                   op: LedgerOPType(rawValue: r["op"]!.asInt()!)!,
                                   token: r["token"]!.asString()!,
                                   ref: r["transaction_group"]!.asString()!,
                                   address: r["owner"]!.asString()!,
                                   date: r["date"]!.asUInt64()!,
                                   auth: r["spend_auth"]!.asString()!,
                                   block: UInt32(r["block"]!.asUInt64()!))
                    
                    b.transactions.append(l)
                    
                }
                
            }
            
            return b
        }
        
        return nil;
    }
    
    class func PendingLedgersForHeight(_ height: UInt32) -> [Ledger] {
        
        var retValue: [Ledger] = []
        
        // now get the transactions for that block
        let trans = pending_db.query(sql: "SELECT * FROM ledger WHERE block = ? ORDER BY token", params: [UInt64(height)])
        
        if trans.error == nil && trans.results.count > 0 {
            
            for r in trans.results {
                
                let l = Ledger(id: r["transaction_id"]!.asString()!,
                               op: LedgerOPType(rawValue: r["op"]!.asInt()!)!,
                               token: r["token"]!.asString()!,
                               ref: r["transaction_group"]!.asString()!,
                               address: r["owner"]!.asString()!,
                               date: r["date"]!.asUInt64()!,
                               auth: r["spend_auth"]!.asString()!,
                               block: UInt32(r["block"]!.asUInt64()!))
                
                retValue.append(l)
                
            }
            
        }
        
        return retValue;
    }
    
    class func OreBlocks() -> [Block] {
        
        var retValue: [Block] = []
        
        let result = blockchain_db.query(sql: "SELECT * FROM block WHERE oreSeed IS NOT NULL", params: [])
        
        if result.results.count > 0 {
            
            for br in result.results {
                
                let b = Block(height: UInt32(br["height"]!.asUInt64()!))
                b.oreSeed = br["oreSeed"]?.asString()
                retValue.append(b)
                
            }
            
        } else {
            
            debug("(Database) call to 'OreBlocks() -> [Block]' returned no results.")
            
        }
        
        return retValue
        
    }
    
}
