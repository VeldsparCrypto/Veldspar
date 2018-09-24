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

enum BlockchainErrors : Error {
    case TokenHasNoValue
    case InvalidAddress
    case InvalidAlgo
    case InvalidToken
}

class BlockChain {
    
    private let blockchain_lock: Mutex
    private let pending_lock: Mutex
    private let stats_lock: Mutex
    private var current_tidemark: Block?
    private var current_height: Int?
    
    init() {
        
        blockchain_lock = Mutex()
        pending_lock = Mutex()
        stats_lock = Mutex()
        
    }
    
    func getStatsJSON() -> String {
        
        var json = ""
        
        do {
            
            let encodedData = try String(bytes: JSONEncoder().encode(getStats()), encoding: .ascii)
            if encodedData != nil {
                json = encodedData!
            }
            
        } catch {}
        
        return json
        
    }
    
    func getStats() -> RPC_Stats {
        
        var stats: RPC_Stats?
        
        blockchain_lock.mutex {
            
            stats = Database.GetStats()
            
        }
        
        return stats!
        
    }
    
    func setNewHeight(_ newHeight: Int) {
        
        stats_lock.mutex {
            current_height = newHeight
        }
        
    }
    
    func height() -> Int {
        
        var count: Int = 0
        
        stats_lock.mutex {
            if current_height != nil {
                count = current_height!
            }
        }
        
        if count != 0 {
            return count
        }
        
        blockchain_lock.mutex {
            
            // query the database to find the highest block there is
            count = Database.CurrentHeight() ?? 0
            stats_lock.mutex {
                current_height = Int(count)
            }
            
        }
        
        // could legitimately still be zero of course.
        return count
        
    }
    
    func GenerateStatsFor(block: Int) {
        
        blockchain_lock.mutex {
            
            // query the database to find the highest block there is
            stats_lock.mutex {
                Database.WriteStatsRecord(height: block)
            }
            
        }
        
    }
    
    func StatsHeight() -> Int {
        
        var count: Int = 0
        
        blockchain_lock.mutex {
            // query the database to find the highest block there is
            count = Database.StatsHeight()
        }
        
        return count
        
    }
    
    func blockAtHeight(_ height: Int) -> Block? {
        
        var block: Block? = nil
        
        blockchain_lock.mutex {
            // query database
            block = Database.BlockAtHeight(height)
        }
        
        return block
        
    }
    
    func pendingLedgersForBlock(_ height: Int) -> [Ledger] {
        
        var ledgers: [Ledger] = []
        
        pending_lock.mutex {
            ledgers = Database.PendingLedgersForHeight(height)
        }
        
        return ledgers
        
    }
    
    func addBlock(_ block:Block) -> Bool {
        
        var retValue = false
        
        blockchain_lock.mutex {
            
            if block.height > height() {
                retValue = Database.WriteBlock(block)
                if retValue {
                    setNewHeight(Int(block.height))
                }
            }
            
        }
        
        return retValue
        
    }
    
    func oreSeeds() -> [Block] {
        
        var retValue: [Block] = []
        
        blockchain_lock.mutex {
            retValue = Database.OreBlocks()
            
        }
        
        return retValue
        
    }
    
    // ledger functions
    
    func tokenLedger(token: String) -> Ledger? {
        
        var l: Ledger?
        
        do {
            let t = try Token(token)

            blockchain_lock.mutex {
                l = Database.TokenOwnershipRecord(database: blockchain_db, token: t)
            }

        } catch {
            return nil
        }
        
        return l;
        
    }
    
    func tokenLedgerPending(token: String) -> Ledger? {
        
        var l: Ledger?
        
        do {
            let t = try Token(token)
            
            pending_lock.mutex {
                l = Database.TokenOwnershipRecord(database: pending_db, token: t)
            }
            
        } catch {
            return nil
        }
        
        return l;
        
    }
    
    func registerToken(tokenString: String, address: String, block: Int) throws -> Bool {
        
        var returnValue = false
        var token = tokenString
        var t: Token?
        
        let start = Date().timeIntervalSince1970
        
        // first off, check that the token is essentially valid in construction
        // 0-1-32-00018467-00043A62-0006F243
        let components = token.components(separatedBy: "-")
        if components.count != 6 {
            throw BlockchainErrors.InvalidToken
        }
        
        do {
            t = try Token(token)
        } catch {
            throw BlockchainErrors.InvalidToken
        }
        
        // now go and lookup existence in the database
        var databaseToken: Ledger? = nil
        blockchain_lock.mutex {
            databaseToken = Database.TokenOwnershipRecord(database: blockchain_db, token: t!)
        }
        
        if databaseToken == nil {
            
            var err: BlockchainErrors?
            
            pending_lock.mutex {
                if  Database.TokenOwnershipRecord(database: pending_db, token: t!) == nil {
                    
                    // now we validate the find
                    // validate the token
                    do {
                        
                        let t = try Token(token)
                        
                        if AlgorithmManager.sharedInstance().depricated(type: t.algorithm, height: UInt(t.oreHeight)) {
                            logger.log(level: .Warning, log: "(BlockChain) token submitted to 'registerToken(token: String, address: String, block: Int) -> Bool' was of deprecated method.", token: t.tokenStringId(), source: nil, duration: Int((Date().timeIntervalSince1970 - start) * 1000))
                            return
                        }
                        
                        if t.value() == 0 {
                            logger.log(level: .Warning, log: "(BlockChain) token submitted to 'registerToken(token: String, address: String, block: Int) -> Bool' was invalid and has no value.", token: t.tokenStringId(), source: nil, duration: Int((Date().timeIntervalSince1970 - start) * 1000))
                            err = BlockchainErrors.TokenHasNoValue
                            return
                        }
                        
                        // update the token's id
                        token = t.tokenStringId()
                        
                    } catch BlockchainErrors.TokenHasNoValue {
                        err = BlockchainErrors.TokenHasNoValue
                        return
                    } catch {
                        logger.log(level: .Warning, log: "(BlockChain) token submitted to 'registerToken(token: String, address: String, block: Int) -> Bool' caused an exception. '\(error)'", token: token, source: nil, duration: Int((Date().timeIntervalSince1970 - start) * 1000))
                        return
                    }
                    
                    let l = Ledger(op: .RegisterToken, token: token, ref: UUID().uuidString.CryptoHash(), address: address, auth: "", height: block, ore: t!.oreHeight, algo: Int(t!.algorithm.rawValue), value: t!.value(), location: t!.location)
                    if Database.WriteLedger(database: pending_db, ledger: l) == true {
                        logger.log(level: .Warning, log: "(BlockChain) token submitted to 'registerToken(token: String, address: String, block: Int) -> Bool' call to 'Database.WritePendingLedger()' succeeded, token written.", token: token, source: nil, duration: Int((Date().timeIntervalSince1970 - start) * 1000))
                        returnValue = true
                    } else {
                        logger.log(level: .Warning, log: "(BlockChain) token submitted to 'registerToken(token: String, address: String, block: Int) -> Bool' call to 'Database.WritePendingLedger()' failed.", token: token, source: nil, duration: Int((Date().timeIntervalSince1970 - start) * 1000))
                    }
                } else {
                    logger.log(level: .Warning, log: "(BlockChain) token submitted to 'registerToken(token: String, address: String, block: Int) -> Bool' this token exists already in pending.db", token: token, source: nil, duration: Int((Date().timeIntervalSince1970 - start) * 1000))
                }
            }
            
            if err != nil {
                throw err!
            }
            
        } else {
            logger.log(level: .Warning, log: "(BlockChain) token submitted to 'registerToken(token: String, address: String, block: Int) -> Bool' this token exists already in blockchain.db", token: token, source: nil, duration: Int((Date().timeIntervalSince1970 - start) * 1000))
        }

        return returnValue
        
    }
    
    func transferToken(token: String, address: String, block: Int, auth: String, reference: String) -> Bool {
        
        let returnValue = false
        
//        // validate the token
//        do {
//            let t = try Token(address)
//            if t.value() == 0 {
//                return false
//            }
//        } catch {
//            return false
//        }
//
//        lock.mutex {
//
//            if Database.TokenOwnershipRecord(token) == nil && Database.TokenPendingRecord(token) == nil {
//
//                let l = Ledger(op: .ChangeOwner, token: token, ref: reference, address: address, auth: auth, block: block)
//                if Database.WritePendingLedger(l) == true {
//                    returnValue = true
//                }
//
//            }
//
//        }
        
        return returnValue
        
    }
    
    
}
