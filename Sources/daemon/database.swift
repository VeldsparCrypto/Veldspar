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
        _ = blockchain_db.execute(sql: """
CREATE TABLE IF NOT EXISTS stats (
    block INTEGER PRIMARY KEY,
    newTokens INTEGER,
    newValue INTEGER,
    depletion REAL,
    addressCount INTEGER,
    activeAddressCount INTEGER,
    transCount INTEGER,
    reallocTokens INTEGER,
    reallocValue INTEGER,
    d1 INTEGER,
    d2 INTEGER,
    d5 INTEGER,
    d10 INTEGER,
    d20 INTEGER,
    d50 INTEGER,
    d100 INTEGER,
    d200 INTEGER,
    d500 INTEGER,
    d1000 INTEGER,
    d2000 INTEGER,
    d5000 INTEGER)
""", params: [])
        _ = blockchain_db.execute(sql: """
CREATE VIEW IF NOT EXISTS stats_summary
AS
SELECT MAX(block) as blocks,
SUM(newTokens) as tokens,
SUM(newValue) as value,
(SELECT AVG(depletion) FROM stats WHERE block > (SELECT MAX(block) from stats)-3) as depletion,
(SELECT CAST((CAST(AVG(newTokens) AS REAL) / 2) as REAL)  FROM stats WHERE block > (SELECT MAX(block) from stats)-3) as rate,
MAX(addressCount) as addresses,
SUM(transCount) as transactions,
SUM(d1) as d1,
SUM(d2) as d2,
SUM(d5) as d5,
SUM(d10) as d10,
SUM(d20) as d20,
SUM(d50) as d50,
SUM(d100) as d100,
SUM(d200) as d200,
SUM(d500) as d500,
SUM(d1000) as d1000,
SUM(d2000) as d2000,
SUM(d5000) as d5000  FROM stats;
""", params: [])
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
        
        _ = blockchain_db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_ledger_token ON ledger (token);", params: [])
        _ = blockchain_db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_ledger_block ON ledger (block);", params: [])
        _ = blockchain_db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_ledger_op ON ledger (op);", params: [])
        _ = blockchain_db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_ledger_owner ON ledger (owner);", params: [])
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
        
        _ = pending_db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_ledger_token ON ledger (token);", params: [])
        _ = pending_db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_ledger_block ON ledger (block);", params: [])
        
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
                UInt64(ledger.op.rawValue),
                UInt64(ledger.date),
                ledger.transaction_group,
                ledger.destination,
                Token.compactToken(ledger.token),
                ledger.spend_auth,
                UInt64(ledger.block),
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
                        Token.compactToken(t.token),
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

    class func WriteStatsRecord(block: Int, depletionRate: Double) {
        
        _ = blockchain_db.execute(sql: "BEGIN TRANSACTION", params: [])
        _ = blockchain_db.execute(sql: "DROP TABLE IF EXISTS temp_stats;", params: [])
        _ = blockchain_db.execute(sql: "DROP TABLE IF EXISTS temp_block;", params: [])
        _ = blockchain_db.execute(sql: "CREATE TABLE IF NOT EXISTS temp_block (block INTEGER PRIMARY KEY);", params: [])
        _ = blockchain_db.execute(sql: "INSERT INTO temp_block VALUES (?);", params: [block])
        _ = blockchain_db.execute(sql: "CREATE TABLE IF NOT EXISTS temp_stats (denom TEXT PRIMARY KEY, denom_count INTEGER);", params: [])
        _ = blockchain_db.execute(sql: "INSERT OR REPLACE INTO stats (block) VALUES ((SELECT block FROM temp_block LIMIT 1));", params: [])
        _ = blockchain_db.execute(sql: "INSERT INTO temp_stats SELECT substr(token,19,4) as denom, COUNT(*) as denom_count FROM ledger WHERE block = (SELECT block FROM temp_block LIMIT 1) AND op = 1 GROUP BY substr(token,19,4);", params: [])
        _ = blockchain_db.execute(sql: "UPDATE stats SET newTokens = (SELECT SUM(denom_count) FROM temp_stats) WHERE block = (SELECT block FROM temp_block LIMIT 1);", params: [])
        _ = blockchain_db.execute(sql: "UPDATE stats SET d1 = (SELECT denom_count FROM temp_stats WHERE denom = upper(printf('%04X', 1))) WHERE block = (SELECT block FROM temp_block LIMIT 1);", params: [])
        _ = blockchain_db.execute(sql: "UPDATE stats SET d2 = (SELECT denom_count FROM temp_stats WHERE denom = upper(printf('%04X', 2))) WHERE block = (SELECT block FROM temp_block LIMIT 1);", params: [])
        _ = blockchain_db.execute(sql: "UPDATE stats SET d5 = (SELECT denom_count FROM temp_stats WHERE denom = upper(printf('%04X', 5))) WHERE block = (SELECT block FROM temp_block LIMIT 1);", params: [])
        _ = blockchain_db.execute(sql: "UPDATE stats SET d10 = (SELECT denom_count FROM temp_stats WHERE denom = upper(printf('%04X', 10))) WHERE block = (SELECT block FROM temp_block LIMIT 1);", params: [])
        _ = blockchain_db.execute(sql: "UPDATE stats SET d20 = (SELECT denom_count FROM temp_stats WHERE denom = upper(printf('%04X', 20))) WHERE block = (SELECT block FROM temp_block LIMIT 1);", params: [])
        _ = blockchain_db.execute(sql: "UPDATE stats SET d50 = (SELECT denom_count FROM temp_stats WHERE denom = upper(printf('%04X', 50))) WHERE block = (SELECT block FROM temp_block LIMIT 1);", params: [])
        _ = blockchain_db.execute(sql: "UPDATE stats SET d100 = (SELECT denom_count FROM temp_stats WHERE denom = upper(printf('%04X', 100))) WHERE block = (SELECT block FROM temp_block LIMIT 1);", params: [])
        _ = blockchain_db.execute(sql: "UPDATE stats SET d200 = (SELECT denom_count FROM temp_stats WHERE denom = upper(printf('%04X', 200))) WHERE block = (SELECT block FROM temp_block LIMIT 1);", params: [])
        _ = blockchain_db.execute(sql: "UPDATE stats SET d500 = (SELECT denom_count FROM temp_stats WHERE denom = upper(printf('%04X', 500))) WHERE block = (SELECT block FROM temp_block LIMIT 1);", params: [])
        _ = blockchain_db.execute(sql: "UPDATE stats SET d1000 = (SELECT denom_count FROM temp_stats WHERE denom = upper(printf('%04X', 1000))) WHERE block = (SELECT block FROM temp_block LIMIT 1);", params: [])
        _ = blockchain_db.execute(sql: "UPDATE stats SET d2000 = (SELECT denom_count FROM temp_stats WHERE denom = upper(printf('%04X', 2000))) WHERE block = (SELECT block FROM temp_block LIMIT 1);", params: [])
        _ = blockchain_db.execute(sql: "UPDATE stats SET d5000 = (SELECT denom_count FROM temp_stats WHERE denom = upper(printf('%04X', 5000))) WHERE block = (SELECT block FROM temp_block LIMIT 1);", params: [])
        _ = blockchain_db.execute(sql: "UPDATE stats SET newValue = (SELECT SUM((CAST(denom as INT) * denom_count)) FROM temp_stats) WHERE block = (SELECT block FROM temp_block LIMIT 1);", params: [])
        _ = blockchain_db.execute(sql: "UPDATE stats SET addressCount = (SELECT COUNT(DISTINCT owner) FROM ledger WHERE block <= (SELECT block FROM temp_block LIMIT 1)) WHERE block = (SELECT block FROM temp_block LIMIT 1);", params: [])
        _ = blockchain_db.execute(sql: "UPDATE stats SET activeAddressCount = (SELECT COUNT(DISTINCT owner) FROM ledger WHERE block = (SELECT block FROM temp_block LIMIT 1)) WHERE block = (SELECT block FROM temp_block LIMIT 1);", params: [])
        _ = blockchain_db.execute(sql: "UPDATE stats SET transCount = (SELECT COUNT(*) FROM ledger WHERE block = (SELECT block FROM temp_block LIMIT 1)) WHERE block = (SELECT block FROM temp_block LIMIT 1);", params: [])
        _ = blockchain_db.execute(sql: "UPDATE stats SET reallocTokens = (SELECT COUNT(*) FROM ledger WHERE block = (SELECT block FROM temp_block LIMIT 1) AND op = 2) WHERE block = (SELECT block FROM temp_block LIMIT 1);", params: [])
        _ = blockchain_db.execute(sql: "DELETE FROM temp_stats;", params: [])
        _ = blockchain_db.execute(sql: "INSERT INTO temp_stats SELECT substr(token,19,4) as denom, COUNT(*) as denom_count FROM ledger WHERE block = (SELECT block FROM temp_block LIMIT 1) AND op = 2 GROUP BY substr(token,19,4);", params: [])
        _ = blockchain_db.execute(sql: "UPDATE stats SET reallocValue = (SELECT SUM((CAST(denom as INT) * denom_count)) FROM temp_stats) WHERE block = (SELECT block FROM temp_block LIMIT 1);", params: [])
        _ = blockchain_db.execute(sql: "UPDATE stats SET depletion = ? WHERE block = (SELECT block FROM temp_block LIMIT 1);", params: [depletionRate])
        _ = blockchain_db.execute(sql: "DROP TABLE IF EXISTS temp_stats;", params: [])
        _ = blockchain_db.execute(sql: "DROP TABLE IF EXISTS temp_block;", params: [])
        _ = blockchain_db.execute(sql: "COMMIT TRANSACTION;", params: [])
        
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
    
    class func StatsHeight() -> Int {
        
        let result = blockchain_db.query(sql: "SELECT blocks FROM stats_summary ORDER BY blocks DESC LIMIT 1", params: [])
        if result.error != nil {
            return 0
        }
        
        if result.results.count > 0 {
            let r = result.results[0]
            return Int(r["blocks"]!.asInt() ?? 0)
        }
        
        return 0;
        
    }
    
    class func GetStats() -> RPC_Stats {
        
        let summary_stats = blockchain_db.query(sql: "SELECT * FROM stats_summary;", params: [])
        if summary_stats.error != nil {
            return RPC_Stats();
        }
        
        if summary_stats.results.count > 0 {
            
            let stats = blockchain_db.query(sql: "SELECT * FROM stats ORDER BY block", params: [])
            if stats.error != nil {
                return RPC_Stats();
            }
            
            if stats.results.count > 0 {
                
                // build the summary
                let rpcstats = RPC_Stats()
                rpcstats.depletion = summary_stats.results[0]["depletion"]!.asDouble() ?? 0
                rpcstats.height = summary_stats.results[0]["blocks"]!.asInt() ?? 0
                rpcstats.tokens = summary_stats.results[0]["tokens"]!.asInt() ?? 0
                rpcstats.value = Double(summary_stats.results[0]["value"]!.asInt() ?? 0)
                rpcstats.rate = summary_stats.results[0]["rate"]!.asDouble() ?? 0
                rpcstats.transactions = summary_stats.results[0]["transactions"]!.asInt() ?? 0
                rpcstats.addresses = summary_stats.results[0]["addresses"]!.asInt() ?? 0
                
                rpcstats.value = Double(rpcstats.value) / Double(Config.DenominationDivider)
                
                rpcstats.denominations["0.01"] = summary_stats.results[0]["d1"]!.asInt() ?? 0
                rpcstats.denominations["0.02"] = summary_stats.results[0]["d2"]!.asInt() ?? 0
                rpcstats.denominations["0.05"] = summary_stats.results[0]["d5"]!.asInt() ?? 0
                rpcstats.denominations["0.10"] = summary_stats.results[0]["d10"]!.asInt() ?? 0
                rpcstats.denominations["0.20"] = summary_stats.results[0]["d20"]!.asInt() ?? 0
                rpcstats.denominations["0.50"] = summary_stats.results[0]["d50"]!.asInt() ?? 0
                rpcstats.denominations["1.00"] = summary_stats.results[0]["d100"]!.asInt() ?? 0
                rpcstats.denominations["2.00"] = summary_stats.results[0]["d200"]!.asInt() ?? 0
                rpcstats.denominations["5.00"] = summary_stats.results[0]["d500"]!.asInt() ?? 0
                rpcstats.denominations["10.00"] = summary_stats.results[0]["d1000"]!.asInt() ?? 0
                rpcstats.denominations["20.00"] = summary_stats.results[0]["d2000"]!.asInt() ?? 0
                rpcstats.denominations["50.00"] = summary_stats.results[0]["d5000"]!.asInt() ?? 0
                
                for s in stats.results {
                    
                    let block = RPC_StatsBlock()
                    block.height = s["block"]!.asInt() ?? 0
                    block.newTokens = s["newTokens"]!.asInt() ?? 0
                    block.newValue = s["newValue"]!.asInt() ?? 0
                    block.depletion = s["depletion"]!.asDouble() ?? 0
                    block.addressHeight = s["addressCount"]!.asInt() ?? 0
                    block.activeAddresses = s["activeAddressCount"]!.asInt() ?? 0
                    block.reallocTokens = s["block"]!.asInt() ?? 0
                    block.reallocValue = s["block"]!.asInt() ?? 0
                    
                    block.denominations["0.01"] = s["d1"]!.asInt() ?? 0
                    block.denominations["0.02"] = s["d2"]!.asInt() ?? 0
                    block.denominations["0.05"] = s["d5"]!.asInt() ?? 0
                    block.denominations["0.10"] = s["d10"]!.asInt() ?? 0
                    block.denominations["0.20"] = s["d20"]!.asInt() ?? 0
                    block.denominations["0.50"] = s["d50"]!.asInt() ?? 0
                    block.denominations["1.00"] = s["d100"]!.asInt() ?? 0
                    block.denominations["2.00"] = s["d200"]!.asInt() ?? 0
                    block.denominations["5.00"] = s["d500"]!.asInt() ?? 0
                    block.denominations["10.00"] = s["d1000"]!.asInt() ?? 0
                    block.denominations["20.00"] = s["d2000"]!.asInt() ?? 0
                    block.denominations["50.00"] = s["d5000"]!.asInt() ?? 0
                    
                    rpcstats.blocks.append(block)
                    
                }
                
                return rpcstats
                
            }
            
        }
        
        return RPC_Stats()
        
    }
    
    class func CountAddresses() -> Int {
        
        let result = blockchain_db.query(sql: "SELECT COUNT(DISTINCT owner) as count_owner FROM ledger;", params: [])
        if result.error != nil {
            return 0
        }
        
        if result.results.count > 0 {
            let r = result.results[0]
            return Int(r["count_owner"]!.asUInt64()!)
        }
        
        return 0;
    }
    
    class func LedgersConcerningAddress(_ address: String, lastRowHeight: Int) -> [(Int,Ledger)] {
        
        let result = blockchain_db.query(sql: "SELECT ROWID,* FROM ledger WHERE token IN (SELECT DISTINCT token FROM ledger WHERE owner = ?) AND ROWID > ? ORDER BY block ASC LIMIT 10000", params: [address, lastRowHeight])
        if result.error != nil {
            return []
        }
        
        if result.results.count > 0 {
            var ledgers: [(Int,Ledger)] = []
            for r in result.results {
                let l = Ledger(id: r["transaction_id"]!.asString()!,
                               op: LedgerOPType(rawValue: r["op"]!.asInt()!)!,
                               token: Token.expandToken(r["token"]!.asString()!),
                               ref: r["transaction_group"]!.asString()!,
                               address: r["owner"]!.asString()!,
                               date: r["date"]!.asUInt64()!,
                               auth: r["spend_auth"]!.asString()!,
                               block: UInt32(r["block"]!.asUInt64()!))
                ledgers.append((Int(r["rowid"]!.asUInt64()!),l))
            }
            return ledgers
        }
        
        return [];
    }
    
    class func TokenOwnershipRecord(_ id: String) -> Ledger? {
        
        let result = blockchain_db.query(sql: "SELECT * FROM ledger WHERE token = ? ORDER BY block DESC LIMIT 1", params: [Token.compactToken(id)])
        if result.error != nil {
            return nil
        }
        
        if result.results.count > 0 {
            let r = result.results[0]
            let l = Ledger(id: r["transaction_id"]!.asString()!,
                           op: LedgerOPType(rawValue: r["op"]!.asInt()!)!,
                           token: Token.expandToken(r["token"]!.asString()!),
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
        
        let result = pending_db.query(sql: "SELECT * FROM ledger WHERE token = ? ORDER BY block DESC LIMIT 1", params: [Token.compactToken(id)])
        if result.error != nil {
            return nil
        }
        
        if result.results.count > 0 {
            let r = result.results[0]
            let l = Ledger(id: r["transaction_id"]!.asString()!,
                           op: LedgerOPType(rawValue: r["op"]!.asInt()!)!,
                           token: Token.expandToken(r["token"]!.asString()!),
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
                                   token: Token.expandToken(r["token"]!.asString()!),
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
                               token: Token.expandToken(r["token"]!.asString()!),
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
