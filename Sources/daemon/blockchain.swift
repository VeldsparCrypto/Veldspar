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
    
    private let lock: Mutex
    public let lockStats: Mutex
    private var current_tidemark: Block?
    private var stats = RPC_Stats()
    private var depletion: Double = 0.0
    private var creation: Double = 0.0
    
    init() {
        
        lock = Mutex()
        lockStats = Mutex()
        
    }
    
    func getStatsJSON() -> String {
        
        var json = ""
        
        lockStats.mutex {
            
            do {
                
                let encodedData = try String(bytes: JSONEncoder().encode(stats), encoding: .ascii)
                if encodedData != nil {
                    json = encodedData!
                }
                
            } catch {}
            
        }
        
        return json
        
    }
    
    func getStats() -> RPC_Stats {
        
        var retStats: RPC_Stats?
        
        lockStats.mutex {
            
            retStats = stats
            
        }
        
        return retStats!
        
    }
    

    
    func height() -> UInt32 {
        
        var count: UInt32 = 0
        
        lock.mutex {
            
            // query the database to find the highest block there is
            count = Database.CurrentHeight() ?? 0
            
        }
        
        return count
        
    }
    
    func IncrementCreation() {
        
        lock.mutex {
            creation += 1.0;
        }
        
    }
    
    func IncrementDepletion() {
        
        lock.mutex {
            depletion += 1.0;
        }
        
    }
    
    func GenerateStatsFor(block: Int) {
        
        lock.mutex {
            
            // query the database to find the highest block there is
            if creation == 0.0 {
                creation = 1.0
            }
            Database.WriteStatsRecord(block: block, depletionRate: ((depletion / creation) * 100.0))
            depletion = 0;
            creation = 0;
            
        }
        
    }
    
    func StatsHeight() -> Int {
        
        var count: Int = 0
        
        lock.mutex {
            
            // query the database to find the highest block there is
            count = Database.StatsHeight()
            
        }
        
        return count
        
    }
    
    func blockAtHeight(_ height: UInt32) -> Block? {
        
        var block: Block? = nil
        
        lock.mutex {
            
            // query database
            block = Database.BlockAtHeight(height)
            
        }
        
        return block
        
    }
    
    func pendingLedgersForBlock(_ height: UInt32) -> [Ledger] {
        
        var ledgers: [Ledger] = []
        
        lock.mutex {
            
            ledgers = Database.PendingLedgersForHeight(height)
            
        }
        
        return ledgers
        
    }
    
    func addBlock(_ block:Block) -> Bool {
        
        var retValue = false
        
        lock.mutex {
            
            if block.height > Database.CurrentHeight()! {
                retValue = Database.WriteBlock(block)
            }
            
        }
        
        return retValue
        
    }
    
    func oreSeeds() -> [Block] {
        
        var retValue: [Block] = []
        
        lock.mutex {
            retValue = Database.OreBlocks()
            
        }
        
        return retValue
        
    }
    
    // ledger functions
    
    func tokenLedger(token: String) -> Ledger? {
        
        var l: Ledger?
        
        lock.mutex {
            l = Database.TokenOwnershipRecord(token)
        }
        
        return l;
        
    }
    
    func tokenLedgerPending(token: String) -> Ledger? {
        
        var l: Ledger?
        
        lock.mutex {
            l = Database.TokenPendingRecord(token)
        }
        
        return l;
        
    }
    
    func registerToken(tokenString: String, address: String, block: UInt32) throws -> Bool {
        
        var returnValue = false
        var token = tokenString
        
        // validate the token
        do {
            
            let t = try Token(token)
            
            if AlgorithmManager.sharedInstance().depricated(type: t.algorithm, height: UInt(t.oreHeight)) {
                debug("(BlockChain) token submitted to 'registerToken(token: String, address: String, block: UInt32) -> Bool' was of deprecated method.")
                return false
            }
            
            if t.value() == 0 {
                debug("(BlockChain) token submitted to 'registerToken(token: String, address: String, block: UInt32) -> Bool' was invalid and has no value.")
                throw BlockchainErrors.TokenHasNoValue
            }
            
            // update the token's id
            token = t.tokenId()
            
        } catch BlockchainErrors.TokenHasNoValue {
            throw BlockchainErrors.TokenHasNoValue
        } catch {
            debug("(BlockChain) token submitted to 'registerToken(token: String, address: String, block: UInt32) -> Bool' caused an exception. '\(error)'")
            return false
        }
        
        lock.mutex {
            
            if Database.TokenOwnershipRecord(token) == nil && Database.TokenPendingRecord(token) == nil {
                
                let l = Ledger(op: .RegisterToken, token: token, ref: UUID().uuidString, address: address, auth: "", block: block)
                if Database.WritePendingLedger(l) == true {
                    returnValue = true
                } else {
                    debug("(BlockChain) token submitted to 'registerToken(token: String, address: String, block: UInt32) -> Bool' call to 'Database.WritePendingLedger()' failed.")
                }
                
            } else {
                
                debug("(BlockChain) token submitted to 'registerToken(token: String, address: String, block: UInt32) -> Bool' this token exists already.")
                
            }
            
        }
        
        return returnValue
        
    }
    
    func transferToken(token: String, address: String, block: UInt32, auth: String, reference: String) -> Bool {
        
        var returnValue = false
        
        // validate the token
        do {
            let t = try Token(address)
            if t.value() == 0 {
                return false
            }
        } catch {
            return false
        }
        
        lock.mutex {
            
            if Database.TokenOwnershipRecord(token) == nil && Database.TokenPendingRecord(token) == nil {
                
                let l = Ledger(op: .ChangeOwner, token: token, ref: reference, address: address, auth: auth, block: block)
                if Database.WritePendingLedger(l) == true {
                    returnValue = true
                }
                
            }
            
        }
        
        return returnValue
        
    }
    
    func ledgersConcerningAddress(_ address: String, lastRowHeight: Int) -> [(Int,Ledger)] {
        
        var l: [(Int,Ledger)] = []
        
        lock.mutex {
            l = Database.LedgersConcerningAddress(address, lastRowHeight: lastRowHeight)
        }
        
        return l;
        
    }
    
    
}
