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
    private let stats_lock: Mutex
    private var current_tidemark: Block?
    private var current_height: Int?
    
    init() {
        
        blockchain_lock = Mutex()
        stats_lock = Mutex()
        
    }
    
    func setNewHeight(_ newHeight: Int) {
        
        stats_lock.mutex {
            current_height = newHeight
        }
        
    }
    
    func height() -> Int {
        
        var count: Int = -1
        
        stats_lock.mutex {
            if current_height != nil {
                count = current_height!
            }
        }
        
        if count != -1 {
            return count
        }
        
        blockchain_lock.mutex {
            
            // query the database to find the highest block there is
            count = Database.CurrentHeight() ?? -1
            stats_lock.mutex {
                current_height = Int(count)
            }
            
        }
        
        // could legitimately still be zero of course.
        return count
        
    }
    
    func blockAtHeight(_ height: Int, includeTransactions: Bool) -> Block? {
        
        var block: Block? = nil
        
        blockchain_lock.mutex {
            // query database
            block = Database.BlockAtHeight(height, includeTransactions: includeTransactions)
        }
        
        return block
        
    }
    
    func LedgersForBlock(_ height: Int) -> [Ledger] {
        
        var ledgers: [Ledger] = []
        
        blockchain_lock.mutex {
            ledgers = Database.LedgersForHeight(height)
        }
        
        return ledgers
        
    }
    
    func addBlock(_ block:Block) -> Bool {
        
        var retValue = false
        
        blockchain_lock.mutex {
            
            if block.height! > height() {
                retValue = Database.WriteBlock(block)
                if retValue {
                    setNewHeight(Int(block.height!))
                }
            }
            
        }
        
        return retValue
        
    }
    
    func setTransactionStateForHeight(height: Int, state: LedgerTransactionState) {
        
        blockchain_lock.mutex {
            Database.SetTransactionStateForHeight(height: height, state: state)
        }
        
    }

    
    // ledger functions
    
    func transferOwnership(request: TransferRequest) -> Bool {
        
        var retValue = true
        
        blockchain_lock.mutex {
            if Database.VerifyOwnership(tokens: request.tokens, address: request.source_address!) {
                // now get the data layer to insert new transfer records
                
                
                
            } else {
                // failed the verify
                retValue = false
            }
        }
        
        return retValue
        
    }
    
    func tokenOwnership(token: String) -> [Ledger] {
        
        var l: [Ledger] = []
        
        do {
            let t = try Token(token)

            blockchain_lock.mutex {
                l = Database.TokenOwnershipRecords(ore: t.oreHeight, address: t.address)
            }

        } catch {
            return []
        }
        
        return l;
        
    }
    
    func registerToken(tokenString: String, address: String, bean: String, block: Int) throws -> Bool {
        
        var returnValue = false
        var token = tokenString
        var t: Token?
        
        // first off, check that the token is essentially valid in construction
        // 0-1-32-00018467-00043A62-0006F243
        let components = token.components(separatedBy: "-")
        if components.count != 4 {
            throw BlockchainErrors.InvalidToken
        }
        
        do {
            t = try Token(token)
        } catch {
            throw BlockchainErrors.InvalidToken
        }
        
        if !t!.validateFind(bean: bean) {
            throw BlockchainErrors.InvalidToken
        }
        
        // now go and lookup existence in the database
        var ownership: [Ledger] = []
        blockchain_lock.mutex {
            ownership = Database.TokenOwnershipRecords(ore: t!.oreHeight, address: t!.address)
        }
        
        if ownership.count == 0 {
            
            let t = try Token(token)
            
            if AlgorithmManager.sharedInstance().depricated(type: t.algorithm, height: UInt(t.oreHeight)) {
                logger.log(level: .Warning, log: "(BlockChain) token submitted to 'registerToken(token: String, address: String, block: Int) -> Bool' was of deprecated method.")
                throw BlockchainErrors.InvalidAlgo
            }
            
            if t.value() == 0 {
                logger.log(level: .Warning, log: "(BlockChain) token submitted to 'registerToken(token: String, address: String, block: Int) -> Bool' was invalid and has no value.")
                throw BlockchainErrors.TokenHasNoValue
            }
            
            // update the token's id
            token = t.tokenStringId()
            
            var l = Ledger()
            l.op = LedgerOPType.RegisterToken.rawValue
            l.address = t.address
            l.height = block
            l.algorithm = t.algorithm.rawValue
            l.date = consensusTime()
            l.destination = Crypto.strAddressToData(address: address)
            l.ore = t.oreHeight
            l.state = LedgerTransactionState.Pending.rawValue
            l.transaction_id = Data(bytes: UUID().uuidString.bytes.sha224())
            l.value = t.value()
            
            blockchain_lock.mutex {
                if Database.WriteLedger(l) == true {
                    logger.log(level: .Warning, log: "(BlockChain) token submitted to 'registerToken(token: String, address: String, block: Int) -> Bool' call to 'Database.WritePendingLedger()' succeeded, token written.")
                    returnValue = true
                } else {
                    logger.log(level: .Warning, log: "(BlockChain) token submitted to 'registerToken(token: String, address: String, block: Int) -> Bool' call to 'Database.WritePendingLedger()' failed.")
            }
            }
            
        } else {
            logger.log(level: .Warning, log: "(BlockChain) token submitted to 'registerToken(token: String, address: String, block: Int) -> Bool' this token exists already in blockchain.db")
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
