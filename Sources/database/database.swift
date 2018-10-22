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
        
        _ = db.execute(sql: "PRAGMA cache_size = -128000;", params: [])
        
        _ = db.execute(sql: "CREATE TABLE IF NOT EXISTS block (height INTEGER PRIMARY KEY, hash TEXT, oreSeed TEXT, confirms INTEGER, rejections INTEGER)", params: [])
        
         _ = db.execute(sql: "CREATE TABLE IF NOT EXISTS nodes (id INTEGER PRIMARY KEY, node_id TEXT, address TEXT, speed INTEGER, last_comm INTEGER)", params: [])
        
        _ = db.execute(sql: "CREATE TABLE IF NOT EXISTS ledger (id INTEGER PRIMARY KEY AUTOINCREMENT)", params: [])
        _ = db.execute(sql: "ALTER TABLE ledger ADD COLUMN op INTEGER", params: [], silenceErrors:true)
        _ = db.execute(sql: "ALTER TABLE ledger ADD COLUMN date INTEGER", params: [], silenceErrors:true)
        _ = db.execute(sql: "ALTER TABLE ledger ADD COLUMN transaction_ref TEXT", params: [], silenceErrors:true)
        _ = db.execute(sql: "ALTER TABLE ledger ADD COLUMN destination TEXT", params: [], silenceErrors:true)
        _ = db.execute(sql: "ALTER TABLE ledger ADD COLUMN ore INTEGER", params: [], silenceErrors:true)
        _ = db.execute(sql: "ALTER TABLE ledger ADD COLUMN address BLOB", params: [], silenceErrors:true)
        _ = db.execute(sql: "ALTER TABLE ledger ADD COLUMN auth TEXT", params: [], silenceErrors:true)
        _ = db.execute(sql: "ALTER TABLE ledger ADD COLUMN height INTEGER", params: [], silenceErrors:true)
        _ = db.execute(sql: "ALTER TABLE ledger ADD COLUMN algorithm INTEGER", params: [], silenceErrors:true)
        _ = db.execute(sql: "ALTER TABLE ledger ADD COLUMN value INTEGER", params: [], silenceErrors:true)
        _ = db.execute(sql: "ALTER TABLE ledger ADD COLUMN state INTEGER", params: [], silenceErrors:true)
        _ = db.execute(sql: "ALTER TABLE ledger ADD COLUMN source_node TEXT", params: [], silenceErrors:true)
        _ = db.execute(sql: "ALTER TABLE ledger ADD COLUMN hash TEXT", params: [], silenceErrors:true)
        _ = db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_ledger_address ON ledger (address);", params: [])
        _ = db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_ledger_height ON ledger (height);", params: [])
        
    }
    
    class func DeleteBlock(_ block: Block) -> Bool {
        
        if db.execute(sql: "DELETE FROM block WHERE height = ?;", params: [block.height, block.height]).error != nil {
            return false
        }
        
        if db.execute(sql: "DELETE FROM ledger WHERE height = ?;", params: [block.height, block.height]).error != nil {
            return false
        }
        
        return true
    }
    
    class func WriteLedger(ledger: Ledger) -> Bool {
        
        var locations:[String] = []
        for i in 0...(Config.TokenAddressSize - 1) {
            locations.append("loc\(i)")
        }

        var params: [Any] = []
        params.append(ledger.transaction_id)
        params.append(UInt64(ledger.op.rawValue))
        params.append(UInt64(ledger.date))
        params.append(ledger.transaction_ref)
        params.append(ledger.destination)
        params.append(ledger.ore)
        for l in ledger.location {
            params.append(l)
        }
        params.append(ledger.auth)
        params.append(ledger.height)
        params.append(ledger.checksum())
        params.append(ledger.algo)
        params.append(ledger.value)
        
        var placeholders: [String] = []
        for _ in params {
            placeholders.append("?")
        }
        
        if database.execute(
            sql: "INSERT OR REPLACE INTO ledger (transaction_id, op, date, transaction_ref, owner, ore, \(locations.joined(separator: ", ")), auth, height, checksum, algorithm, val) VALUES (\(placeholders.joined(separator: ",")));",
            params: params).error != nil {
            return false
            
        }
        return true
        
    }
    
    class func WriteBlock(_ block: Block) -> Bool {
        
        // TODO: transaction & rollback
        
        _ = db.execute(sql: "BEGIN TRANSACTION", params: [])
        if db.execute(sql: "INSERT OR REPLACE INTO block (height, hash, oreSeed, confirms, rejections) VALUES (?,?,?,?,?)", params: [UInt64(block.height), block.hash!, block.oreSeed ?? NSNull(), block.confirms, block.rejections]).error == nil {
            
            // now write in the transactions into the table as well
            for ledger in block.transactions {
                
                if WriteLedger(database: db, ledger: ledger) == false {
                    
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

    class func WriteStatsRecord(height: Int) {
        
        _ = db.execute(sql: "BEGIN TRANSACTION", params: [])
        _ = db.execute(sql: "DROP TABLE IF EXISTS temp_stats;", params: [])
        _ = db.execute(sql: "CREATE TABLE IF NOT EXISTS temp_stats (denom TEXT PRIMARY KEY, denom_count INTEGER);", params: [])
        _ = db.execute(sql: "INSERT OR REPLACE INTO stats (height) VALUES (?);", params: [height])
        _ = db.execute(sql: "INSERT INTO temp_stats SELECT val as denom, COUNT(*) as denom_count FROM ledger INDEXED BY idx_ledger_block WHERE height = ? AND op = 1 GROUP BY denom;", params: [height])
        _ = db.execute(sql: "UPDATE stats SET newCoins = (SELECT SUM(denom_count) FROM temp_stats) WHERE height = ?;", params: [height])
        _ = db.execute(sql: "UPDATE stats SET d1 = (SELECT denom_count FROM temp_stats WHERE denom = 1) WHERE height = ?;", params: [height])
        _ = db.execute(sql: "UPDATE stats SET d2 = (SELECT denom_count FROM temp_stats WHERE denom = 2) WHERE height = ?;", params: [height])
        _ = db.execute(sql: "UPDATE stats SET d5 = (SELECT denom_count FROM temp_stats WHERE denom = 5) WHERE height = ?;", params: [height])
        _ = db.execute(sql: "UPDATE stats SET d10 = (SELECT denom_count FROM temp_stats WHERE denom = 10) WHERE height = ?;", params: [height])
        _ = db.execute(sql: "UPDATE stats SET d20 = (SELECT denom_count FROM temp_stats WHERE denom = 20) WHERE height = ?;", params: [height])
        _ = db.execute(sql: "UPDATE stats SET d50 = (SELECT denom_count FROM temp_stats WHERE denom = 50) WHERE height = ?;", params: [height])
        _ = db.execute(sql: "UPDATE stats SET d100 = (SELECT denom_count FROM temp_stats WHERE denom = 100) WHERE height = ?;", params: [height])
        _ = db.execute(sql: "UPDATE stats SET d200 = (SELECT denom_count FROM temp_stats WHERE denom = 200) WHERE height = ?;", params: [height])
        _ = db.execute(sql: "UPDATE stats SET d500 = (SELECT denom_count FROM temp_stats WHERE denom = 500) WHERE height = ?;", params: [height])
        _ = db.execute(sql: "UPDATE stats SET d1000 = (SELECT denom_count FROM temp_stats WHERE denom = 1000) WHERE height = ?;", params: [height])
        _ = db.execute(sql: "UPDATE stats SET d2000 = (SELECT denom_count FROM temp_stats WHERE denom = 2000) WHERE height = ?;", params: [height])
        _ = db.execute(sql: "UPDATE stats SET d5000 = (SELECT denom_count FROM temp_stats WHERE denom = 5000) WHERE height = ?;", params: [height])
        _ = db.execute(sql: "UPDATE stats SET newValue = (SELECT SUM((CAST(denom as INT) * denom_count)) FROM temp_stats) WHERE height = ?;", params: [height])
        _ = db.execute(sql: "INSERT INTO addresses (address,height) SELECT owner,? FROM ledger WHERE height = ? AND owner NOT IN (SELECT address from addresses);", params: [height,height])
        _ = db.execute(sql: "UPDATE stats SET addressCount = (SELECT COUNT(DISTINCT address) FROM addresses WHERE height <= ?) WHERE height = ?;", params: [height,height])
        _ = db.execute(sql: "UPDATE stats SET activeAddressCount = (SELECT COUNT(DISTINCT owner) FROM ledger WHERE height = ?) WHERE height = ?;", params: [height,height])
        _ = db.execute(sql: "UPDATE stats SET transCount = (SELECT COUNT(*) FROM ledger WHERE height = ?) WHERE height = ?;", params: [])
        _ = db.execute(sql: "UPDATE stats SET reallocCoins = (SELECT COUNT(*) FROM ledger INDEXED BY idx_ledger_block WHERE height = ? AND op = 2) WHERE height = ?;", params: [height,height])
        _ = db.execute(sql: "DELETE FROM temp_stats;", params: [])
        _ = db.execute(sql: "INSERT INTO temp_stats SELECT val as denom, COUNT(*) as denom_count FROM ledger INDEXED BY idx_ledger_block WHERE height = ? AND op = 2 GROUP BY val;", params: [height])
        _ = db.execute(sql: "UPDATE stats SET reallocValue = (SELECT SUM((CAST(denom as INT) * denom_count)) FROM temp_stats) WHERE height = ?;", params: [height])
        _ = db.execute(sql: "DROP TABLE IF EXISTS temp_stats;", params: [])
        _ = db.execute(sql: "DROP TABLE IF EXISTS temp_block;", params: [])
        _ = db.execute(sql: """
DELETE FROM statistics_summary;
""", params: [])
        _ = db.execute(sql: """
INSERT INTO statistics_summary (height,coins,value,rate,addresses,transactions,d1,d2,d5,d10,d20,d50,d100,d200,d500,d1000,d2000,d5000)
SELECT MAX(height) as height,
SUM(newCoins) as coins,
(SUM(d1) + (SUM(d2)*2) + (SUM(d5)*5) + (SUM(d10)*10) + (SUM(d20)*20)  + (SUM(d50)*50) + (SUM(d100)*100) + (SUM(d200)*200) + (SUM(d500)*500) + (SUM(d1000)*1000)  + (SUM(d2000)*2000) + (SUM(d5000)*5000)) as value,
(SELECT CAST((CAST(AVG(newCoins) AS REAL) / 2) as REAL)  FROM stats WHERE height > (SELECT MAX(height) from stats)-3) as rate,
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
SUM(d5000) as d5000 FROM stats;
""", params: [])
        _ = db.execute(sql: "COMMIT TRANSACTION;", params: [])
        
    }
    
    
    class func CurrentHeight() -> Int? {
        
        let result = db.query(sql: "SELECT height FROM block ORDER BY height DESC LIMIT 1", params: [])
        if result.error != nil {
            return nil
        }
        
        if result.results.count > 0 {
            let r = result.results[0]
            return r["height"]!.asInt() ?? 0
        }
        
        return nil;
    }
    
    class func StatsHeight() -> Int {
        
        let result = db.query(sql: "SELECT height FROM stats ORDER BY height DESC LIMIT 1", params: [])
        if result.error != nil {
            return 0
        }
        
        if result.results.count > 0 {
            let r = result.results[0]
            return Int(r["height"]!.asInt() ?? 0)
        }
        
        return 0;
        
    }
    
    class func GetStats() -> RPC_Stats {
        
        let summary_stats = db.query(sql: "SELECT * FROM statistics_summary;", params: [])
        if summary_stats.error != nil {
            return RPC_Stats();
        }
        
        if summary_stats.results.count > 0 {
            
            let stats = db.query(sql: "SELECT * FROM stats ORDER BY height", params: [])
            if stats.error != nil {
                return RPC_Stats();
            }
            
            if stats.results.count > 0 {
                
                // build the summary
                let rpcstats = RPC_Stats()
                rpcstats.height = summary_stats.results[0]["height"]!.asInt() ?? 0
                rpcstats.tokens = summary_stats.results[0]["coins"]!.asInt() ?? 0
                rpcstats.value = summary_stats.results[0]["value"]!.asDouble() ?? 0
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
                    block.height = s["height"]!.asInt() ?? 0
                    block.newCoins = s["newCoins"]!.asInt() ?? 0
                    block.newValue = s["newValue"]!.asInt() ?? 0
                    block.addressHeight = s["addressCount"]!.asInt() ?? 0
                    block.activeAddresses = s["activeAddressCount"]!.asInt() ?? 0
                    block.reallocCoins = s["height"]!.asInt() ?? 0
                    block.reallocValue = s["height"]!.asInt() ?? 0
                    
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
        
        let result = db.query(sql: "SELECT COUNT(DISTINCT owner) as count_owner FROM ledger;", params: [])
        if result.error != nil {
            return 0
        }
        
        if result.results.count > 0 {
            let r = result.results[0]
            return Int(r["count_owner"]!.asUInt64()!)
        }
        
        return 0;
    }
    
    class func TokenOwnershipRecord(database: SWSQLite, token: Token) -> Ledger? {
        
        let t: Token = token
        
        var locations:[String] = []
        for i in 0...(Config.TokenAddressSize - 1) {
            locations.append(" loc\(i) = ? ")
        }
        
        let result = database.query(sql: "SELECT * FROM ledger WHERE \(locations.joined(separator: " AND ")) ORDER BY height DESC LIMIT 1", params:t.location)
        if result.error != nil {
            return nil
        }
        
        if result.results.count > 0 {
            let r = result.results[0]
            var loc:[Int] = []
            for i in 0...(Config.TokenAddressSize - 1) {
                loc.append(r["loc\(i)"]!.asInt() ?? 0)
            }
            
            let l = LedgerFromRecord(r)
                           
            return l
        }
        
        return nil;
    }
    
    class func BlockAtHeight(_ height: Int) -> Block? {
        
        let result = db.query(sql: "SELECT * FROM block WHERE height = ? LIMIT 1", params: [UInt64(height)])
        if result.error != nil {
            return nil
        }
        
        if result.results.count > 0 {
            
            let br = result.results[0]
            let b = Block(height: height)
            b.oreSeed = br["oreSeed"]?.asString()
            b.hash = br["hash"]?.asString()
            b.confirms = br["confirms"]?.asInt() ?? 0
            b.rejections = br["rejections"]?.asInt() ?? 0
            
            var locNames:[String] = []
            for i in 0...(Config.TokenAddressSize - 1) {
                locNames.append("loc\(i)")
            }
            
            // now get the transactions for that block
            let trans = db.query(sql: "SELECT * FROM ledger WHERE height = ? ORDER BY \(locNames.joined(separator: ","))", params: [UInt64(height)])
            if trans.error != nil {
                return nil
            }
            
            if trans.results.count > 0 {
                
                for r in trans.results {
                    
                    var loc:[Int] = []
                    for i in 0...(Config.TokenAddressSize - 1) {
                        loc.append(r["loc\(i)"]!.asInt() ?? 0)
                    }
                    
                    let l = LedgerFromRecord(r)
                    
                    b.transactions.append(l)
                    
                }
                
            }
            
            return b
        }
        
        return nil;
    }
    
    class func LedgerFromRecord(_ r: Record) -> Ledger {
        
        var loc:[Int] = []
        for i in 0...(Config.TokenAddressSize - 1) {
            loc.append(r["loc\(i)"]!.asInt() ?? 0)
        }
        
        let l = Ledger(id: r["transaction_id"]!.asString()!,
                       op: LedgerOPType(rawValue: r["op"]!.asInt()!)!,
                       ref: r["transaction_ref"]!.asString()!,
                       address: r["owner"]!.asString()!,
                       date: r["date"]!.asUInt64()!,
                       auth: r["auth"]!.asString()!,
                       height: r["height"]!.asInt()!,
                       ore: r["ore"]!.asInt()!,
                       algo: r["algorithm"]!.asInt()!,
                       value: r["val"]!.asInt()!,
                       location: loc)
        
        return l
        
    }
    
    class func PendingLedgersForHeight(_ height: Int) -> [Ledger] {
        
        var retValue: [Ledger] = []
        
        var locNames:[String] = []
        for i in 0...(Config.TokenAddressSize - 1) {
            locNames.append("loc\(i)")
        }
        
        // now get the transactions for that block
        let trans = pending_db.query(sql: "SELECT * FROM ledger WHERE height = ? ORDER BY \(locNames.joined(separator: ","))", params: [UInt64(height)])
        
        if trans.error == nil && trans.results.count > 0 {
            
            for r in trans.results {
                
                let l = LedgerFromRecord(r)
                retValue.append(l)
                
            }
            
        }
        
        return retValue;
    }
    
    class func OreBlocks() -> [Block] {
        
        var retValue: [Block] = []
        
        let result = db.query(sql: "SELECT * FROM block WHERE oreSeed IS NOT NULL", params: [])
        
        if result.results.count > 0 {
            
            for br in result.results {
                
                let b = Block(height: br["height"]!.asInt()!)
                b.oreSeed = br["oreSeed"]?.asString()
                retValue.append(b)
                
            }
            
        } else {
            
            
            
        }
        
        return retValue
        
    }
    
}
