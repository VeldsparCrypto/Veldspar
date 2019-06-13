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

let db = SWSQLite(path: "./", filename: "\(Config.CurrencyName).db")

class Database {
    
    class func Initialize() {
        
        db.create(Block(), pk: "height", auto: false, indexes:[])
        db.create(Ledger(), pk: "id", auto: true, indexes:["address,date","height,address","transaction_id","source,height","destination,height"])
        db.create(PeeringNode(), pk: "uuid", auto: false, indexes: [])
        _ = db.execute(sql: "PRAGMA cache_size = -\(8 * 1024)", params: [])
        
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
    
    class func DeleteBlock(_ height: Int) -> Bool {
        
        if db.execute(sql: "DELETE FROM Block WHERE height = ?;", params: [height]).error != nil {
            return false
        }
        
        if db.execute(sql: "DELETE FROM Ledger WHERE height = ?;", params: [height]).error != nil {
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
    
    class func CommitLedger(ledgers: [Ledger], failAll: Bool, op: LedgerOPType) -> Bool {
        
        // after many different versions, I have decided that digital signature checking and authority checking will be done here.  This will allow the data layer to atomically verify the state of the transactions and roll back if invalid transactions are attempted.
        
        var retValue = true
        var changesMade = false
        
        if op == .RegisterToken {
            
            _ = db.execute(sql: "BEGIN TRANSACTION", params: [])
            changesMade = true
            
            // work out which kind of transaction this is
            for l in ledgers {
                
                if l.signatureHash() == l.hash {
                    
                    // record has not been tampered with, now check to see if we already have it in the data store
                    if db.query(sql: "SELECT id FROM Ledger WHERE transaction_id = ? LIMIT 1", params: [l.transaction_id]).results.count == 0 {
                        
                        if l.source == l.destination && TokenOwnershipRecord(ore: l.ore!, address: l.address!).count == 0 {
                            
                            // this is a new registration, so it can be committed right away.  But only after we have validated that it is a valid token to be registered
                            let t = Token(oreHeight: l.ore!, address: l.address!, algorithm: AlgorithmType.init(rawValue: l.algorithm!)!);
                            if t.value() != 0 {
                                l.id = nil
                                changesMade = true
                                _ = db.put(l)
                            } else {
                                retValue = false
                            }
                            
                        } else {
                            
                            // invalid/exists already
                            retValue = false
                            
                        }
                        
                    } else {
                        
                        // record already exists, no action taken
                        retValue = false
                        
                    }
                    
                }
                
            }
            
        } else if op == .ChangeOwner {
            
            // to save nodes lots of processing time, the auth signature is a digitally signed hash of the sorted addresses from within the ledgers.
            // the first ledger in the sorted set should contain the auth for the set
            
            if Crypto.verifySignature(ledgers) {
                
                _ = db.execute(sql: "BEGIN TRANSACTION", params: [])
                changesMade = true
                
                // work out which kind of transaction this is
                for l in ledgers {
                    
                    if l.signatureHash() == l.hash {
                        
                        // record has not been tampered with, now check to see if we already have it in the data store
                        if db.query(sql: "SELECT id FROM Ledger WHERE transaction_id = ? LIMIT 1", params: [l.transaction_id]).results.count == 0 {
                            
                            if l.source != l.destination {
                                
                                // get the current ownership record for this token
                                let current = TokenOwnershipRecord(ore: l.ore!, address: l.address!)
                                if current.count == 0 {
                                    retValue = false
                                } else {
                                    
                                    if current[0].destination != l.source {
                                        retValue = false
                                    } else {
                                        // so the signature is correct, the last destination is this source so we can commit this transaction now.
                                        l.id = nil
                                        l.op = LedgerOPType.ChangeOwner.rawValue
                                        changesMade = true
                                        _ = db.put(l)
                                    }
                                    
                                }
                                
                            }
                            
                        } else {
                            
                            // record already exists, no action taken
                            
                        }
                        
                    }
                    
                }
            }
        }
        
        if changesMade {
            
            if retValue {
                
                _ = db.execute(sql: "COMMIT TRANSACTION;", params: [])
                
            } else {
                
                if failAll {
                    _ = db.execute(sql: "ROLLBACK TRANSACTION;", params: [])
                } else {
                    _ = db.execute(sql: "COMMIT TRANSACTION;", params: [])
                }
                
            }
            
        } else {
            
            retValue = false
            
        }
        
        return retValue
        
    }
    
    class func TokenOwnershipRecord(ore: Int, address: Data) -> [Ledger] {
        
        // get the last ten items, recent->oldest.  Uses status to determine pending and current.
        return db.query(Ledger(), sql: "SELECT * FROM Ledger WHERE ore = ? AND address = ? ORDER BY date DESC LIMIT 1", params: [ore, address])
        
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
    
    class func PendingLedgers(_ tidemark: Int, height: Int) -> [Ledger] {
        
        return db.query(Ledger(), sql: "SELECT * FROM Ledger WHERE id > ? AND height >= ? ORDER BY id LIMIT 1000", params: [tidemark, height])
        
    }
    
    class func WalletAddressContents(address: Data) -> (allocations: [Ledger], spends: [Ledger], mining: [Ledger]) {
        
        // just return the data to free up the DB lock as quickly as possible
        
        let allocation = db.query(Ledger(), sql: "SELECT * FROM Ledger WHERE destination = ? ORDER BY value DESC", params: [address]) as [Ledger]
        let spends = db.query(Ledger(), sql: "SELECT * FROM Ledger WHERE source = ? AND source != destination", params: [address]) as [Ledger]
        
        let mining = db.query(Ledger(), sql: "SELECT * FROM Ledger WHERE source = ? AND destination = ? ORDER BY date DESC LIMIT 30", params: [address, address]) as [Ledger]
        
        return (allocation,spends,mining)
        
    }
    
    class func WalletAddressSummary(address: Data) -> WalletAddress {
        
        // just return the data to free up the DB lock as quickly as possible
        
        let w = WalletAddress()
        w.address = address
        w.alias = []
        w.height = Block.currentNetworkBlockHeight()
        
        let current_balance = db.query(sql: "SELECT SUM(value) as balance FROM Ledger WHERE destination = ? AND id NOT IN (SELECT id FROM Ledger WHERE source = ? AND source != destination) AND height <= ?", params: [address,address,Block.currentNetworkBlockHeight()])
        
        w.current_balance = current_balance.results[0]["balance"]?.asInt() ?? 0
        
        let pending_balance = db.query(sql: "SELECT SUM(value) as balance FROM Ledger WHERE destination = ? AND height > ?", params: [address,Block.currentNetworkBlockHeight()])
        
        w.pending_balance = pending_balance.results[0]["balance"]?.asInt() ?? 0
        
        let spends_out = db.query(sql:
            """
        SELECT
            transaction_ref,
            date,
            destination,
            SUM(value)
        FROM Ledger
        WHERE
            source = ?
        AND
            source != destination
        AND
            op > 1
        AND
            height <= ?
        GROUP BY transaction_ref

""", params: [address,Block.currentNetworkBlockHeight()])
        
        w.outgoing = []
        
        for r in spends_out.results {
            let tfr = WalletTransfer()
            tfr.date = r["date"]?.asUInt64()
            tfr.destination = r["destination"]?.asData()
            tfr.ref = r["transaction_ref"]?.asData()
            tfr.source = address
            tfr.total = r["SUM(value)"]?.asInt()
            w.outgoing.append(tfr)
        }
        
        let spends_out_pending = db.query(sql:
            """
        SELECT
            transaction_ref,
            date,
            destination,
            SUM(value)
        FROM Ledger
        WHERE
            source = ?
        AND
            source != destination
        AND
            op > 1
        AND
            height > ?
        GROUP BY transaction_ref

""", params: [address,Block.currentNetworkBlockHeight()])
        
        w.outgoing_pending = []
        
        for r in spends_out_pending.results {
            let tfr = WalletTransfer()
            tfr.date = r["date"]?.asUInt64()
            tfr.destination = r["destination"]?.asData()
            tfr.ref = r["transaction_ref"]?.asData()
            tfr.source = address
            tfr.total = r["SUM(value)"]?.asInt()
            w.outgoing_pending.append(tfr)
        }
        
        let transfer_in = db.query(sql:
            """
        SELECT
            transaction_ref,
            date,
            source,
            SUM(value)
        FROM Ledger
        WHERE
            destination = ?
        AND
            source != destination
        AND
            op > 1
        AND
            height <= ?
        GROUP BY transaction_ref

""", params: [address, Block.currentNetworkBlockHeight()])
        
        w.incoming = []
        
        for r in transfer_in.results {
            let tfr = WalletTransfer()
            tfr.date = r["date"]?.asUInt64()
            tfr.destination = address
            tfr.ref = r["transaction_ref"]?.asData()
            tfr.source = r["source"]?.asData()
            tfr.total = r["SUM(value)"]?.asInt()
            w.incoming.append(tfr)
        }
        
        let transfer_in_pending = db.query(sql:
            """
        SELECT
            transaction_ref,
            date,
            source,
            SUM(value)
        FROM Ledger
        WHERE
            destination = ?
        AND
            source != destination
        AND
            op > 1
        AND
            height > ?
        GROUP BY transaction_ref

""", params: [address, Block.currentNetworkBlockHeight()])
        
        w.incoming_pending = []
        
        for r in transfer_in_pending.results {
            let tfr = WalletTransfer()
            tfr.date = r["date"]?.asUInt64()
            tfr.destination = address
            tfr.ref = r["transaction_ref"]?.asData()
            tfr.source = r["source"]?.asData()
            tfr.total = r["SUM(value)"]?.asInt()
            w.incoming_pending.append(tfr)
        }
        
        w.mining = db.query(Ledger(), sql: "SELECT * FROM Ledger WHERE op = 1 AND destination = ? ORDER BY date DESC LIMIT 20", params: [address])
        
        return w
        
    }
    
    class func LedgersForAddresses(height: Int, addresses: [Data]) -> [Ledger] {
        
        var params: [Any] = []
        params.append(height)
        params.append(contentsOf: addresses)
        params.append(contentsOf: addresses)
        
        var holders: [String] = []
        for _ in addresses {
            holders.append("?")
        }
        
        let sql = "SELECT * FROM Ledger WHERE height >= ? AND (destination IN (" + holders.joined(separator: ",") + ") OR source IN (" + holders.joined(separator: ",") + ")) ORDER BY height,address"
        
        return db.query(Ledger(), sql: sql, params: params)
        
    }
    
    class func LedgersForHeight(_ height: Int) -> [Ledger] {
        
        return db.query(Ledger(), sql: "SELECT * FROM Ledger WHERE height = ? ORDER BY address", params: [height])
        
    }
    
    class func HashesForBlock(_ height: Int) -> Data {
        
        let result = db.query(sql: "SELECT SHA512(hash) as sha512hash FROM Ledger INDEXED BY idx_Ledger_height_address WHERE height = ?", params: [height])
        for r in result.results {
            return r["sha512hash"]?.asData() ?? Data()
        }
        return Data()
        
    }
    
    class func PeeringNodes() -> [PeeringNode] {
        return db.query(PeeringNode(), sql: "SELECT * FROM PeeringNode", params: [])
    }
    
    class func PeeringNodesReachable() -> [PeeringNode] {
        return db.query(PeeringNode(), sql: "SELECT * FROM PeeringNode WHERE reachable = 1", params: [])
    }
    
    class func WritePeeringNodes(nodes: [PeeringNode]) {
        
        for p in nodes {
            _ = db.put(p)
        }
        
    }
    
}
