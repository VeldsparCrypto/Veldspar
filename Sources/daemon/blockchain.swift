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
}

class BlockChain {
    
    private let blockchain_lock: Mutex
    private let pending_lock: Mutex
    private let stats_lock: Mutex
    private var current_tidemark: Block?
    private var current_height: Int?
    private var depletion: Double = 0.0
    private var creation: Double = 0.0
    
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
    
    func height() -> UInt32 {
        
        var count: UInt32 = 0
        
        stats_lock.mutex {
            if current_height != nil {
                count = UInt32(current_height!)
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
    
    func IncrementCreation() {
        
        stats_lock.mutex {
            creation += 1.0;
        }
        
    }
    
    func IncrementDepletion() {
        
        stats_lock.mutex {
            depletion += 1.0;
        }
        
    }
    
    func GenerateStatsFor(block: Int) {
        
        blockchain_lock.mutex {
            
            // query the database to find the highest block there is
            stats_lock.mutex {
                if creation == 0.0 {
                    creation = 1.0
                }
                Database.WriteStatsRecord(block: block, depletionRate: ((depletion / creation) * 100.0))
                depletion = 0;
                creation = 0;
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
    
    func blockAtHeight(_ height: UInt32) -> Block? {
        
        var block: Block? = nil
        
        blockchain_lock.mutex {
            // query database
            block = Database.BlockAtHeight(height)
        }
        
        return block
        
    }
    
    func pendingLedgersForBlock(_ height: UInt32) -> [Ledger] {
        
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
        
        blockchain_lock.mutex {
            l = Database.TokenOwnershipRecord(token)
        }
        
        return l;
        
    }
    
    func tokenLedgerPending(token: String) -> Ledger? {
        
        var l: Ledger?
        
        pending_lock.mutex {
            l = Database.TokenPendingRecord(token)
        }
        
        return l;
        
    }
    
    func registerToken(tokenString: String, address: String, block: UInt32) throws -> Bool {
        
        var returnValue = false
        var token = tokenString
        
        var start = Date().timeIntervalSince1970
        
        // validate the token
        do {
            
            let t = try Token(token)
            
            if AlgorithmManager.sharedInstance().depricated(type: t.algorithm, height: UInt(t.oreHeight)) {
                logger.log(level: .Warning, log: "(BlockChain) token submitted to 'registerToken(token: String, address: String, block: UInt32) -> Bool' was of deprecated method.", token: t.tokenId(), source: nil, duration: Int((Date().timeIntervalSince1970 - start) * 1000))
                return false
            }
            
            if t.value() == 0 {
                logger.log(level: .Warning, log: "(BlockChain) token submitted to 'registerToken(token: String, address: String, block: UInt32) -> Bool' was invalid and has no value.", token: t.tokenId(), source: nil, duration: Int((Date().timeIntervalSince1970 - start) * 1000))
                throw BlockchainErrors.TokenHasNoValue
            }
            
            // update the token's id
            token = t.tokenId()
            
        } catch BlockchainErrors.TokenHasNoValue {
            throw BlockchainErrors.TokenHasNoValue
        } catch {
            logger.log(level: .Warning, log: "(BlockChain) token submitted to 'registerToken(token: String, address: String, block: UInt32) -> Bool' caused an exception. '\(error)'", token: token, source: nil, duration: Int((Date().timeIntervalSince1970 - start) * 1000))
            return false
        }
        
        start = Date().timeIntervalSince1970
        
        var databaseToken: Ledger? = nil
        blockchain_lock.mutex {
            databaseToken = Database.TokenOwnershipRecord(token)
        }
        
        if databaseToken == nil {
            
            pending_lock.mutex {
                if  Database.TokenPendingRecord(token) == nil {
                    let l = Ledger(op: .RegisterToken, token: token, ref: UUID().uuidString, address: address, auth: "", block: block)
                    if Database.WritePendingLedger(l) == true {
                        returnValue = true
                    } else {
                        logger.log(level: .Warning, log: "(BlockChain) token submitted to 'registerToken(token: String, address: String, block: UInt32) -> Bool' call to 'Database.WritePendingLedger()' failed.", token: token, source: nil, duration: Int((Date().timeIntervalSince1970 - start) * 1000))
                    }
                } else {
                    logger.log(level: .Warning, log: "(BlockChain) token submitted to 'registerToken(token: String, address: String, block: UInt32) -> Bool' this token exists already in pending.db", token: token, source: nil, duration: Int((Date().timeIntervalSince1970 - start) * 1000))
                }
            }
            
        } else {
            logger.log(level: .Warning, log: "(BlockChain) token submitted to 'registerToken(token: String, address: String, block: UInt32) -> Bool' this token exists already in blockchain.db", token: token, source: nil, duration: Int((Date().timeIntervalSince1970 - start) * 1000))
        }
        
        return returnValue
        
    }
    
    func transferToken(token: String, address: String, block: UInt32, auth: String, reference: String) -> Bool {
        
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
    
    func ledgersConcerningAddress(_ address: String, lastRowHeight: Int) -> [(Int,Ledger)] {
        
        var l: [(Int,Ledger)] = []
        
        let start = Date().timeIntervalSince1970
        
        blockchain_lock.mutex {
            l = Database.LedgersConcerningAddress(address, lastRowHeight: lastRowHeight)
        }
        
        logger.log(level: .Warning, log: "(Blockchain) ledgersConcerningAddress for address '\(address)' last height '\(lastRowHeight)'", token: nil, source: nil, duration: Int((Date().timeIntervalSince1970 - start) * 1000))
        
        return l;
        
    }
    
    
}
