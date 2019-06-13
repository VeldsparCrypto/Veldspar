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
    
    func nodesAll() -> [PeeringNode] {
        
        var retValue: [PeeringNode] = []
        
        blockchain_lock.mutex {
            retValue = Database.PeeringNodes()
        }
        
        return retValue
        
    }
    
    func nodesReachable() -> [PeeringNode] {
        
        var retValue: [PeeringNode] = []
        
        blockchain_lock.mutex {
            retValue = Database.PeeringNodesReachable()
        }
        
        return retValue
        
    }
    
    func putNodes(_ nodes: [PeeringNode]) {
        
        blockchain_lock.mutex {
            Database.WritePeeringNodes(nodes: nodes)
        }
        
    }
    
    func purgeStaleNodes() {
        
        blockchain_lock.mutex {
            let max = UInt64(Date().timeIntervalSince1970 * 1000) - 120000
            _ = db.execute(sql: "DELETE FROM PeeringNode WHERE lastcomm < ?", params: [max])
        }
        
    }
    
    func putNode(_ node: PeeringNode) {
        
        blockchain_lock.mutex {
            Database.WritePeeringNodes(nodes: [node])
        }
        
    }
    
    func setNewHeight(_ newHeight: Int) {
        
        stats_lock.mutex {
            self.current_height = newHeight
        }
        
    }
    
    func height() -> Int {
        
        var count: Int = -1
        
        stats_lock.mutex {
            if self.current_height != nil {
                count = self.current_height!
            }
        }
        
        if count != -1 {
            return count
        }
        
        blockchain_lock.mutex {
            
            // query the database to find the highest block there is
            count = Database.CurrentHeight() ?? -1
            self.stats_lock.mutex {
                self.current_height = Int(count)
            }
            
        }
        
        // could legitimately still be zero of course.
        return count
        
    }
    
    func removeBlockAtHeight(_ height: Int) -> Bool {
        
        var ret = false;
        
        blockchain_lock.mutex {
            ret = Database.DeleteBlock(height)
        }
        
        return ret
        
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
    
    func LedgersForAddress(_ height: Int, addresses: [Data]) -> [Ledger] {
        
        var ledgers: [Ledger] = []
        
        blockchain_lock.mutex {
            ledgers = Database.LedgersForAddresses(height: height, addresses: addresses)
        }
        
        return ledgers
        
    }
    
    func GenerateTransferRequest(owner: Data, destination: Data, reference: Data?, amount: Int) -> TransferRequest? {
        
        // get me all the tokens, these are sorted largest to smallest
        let current = CurrentlyOwnedTokens(address: owner)
        let ref = reference ?? "\(UUID().uuidString.prefix(24))".base58EncodedString.base58DecodedData
        
        var leftToFind: Int = amount
        var leftToFee: Int = Config.NetworkFee
        
        var fee_tokens: [Ledger] = []
        var pay_tokens: [Ledger] = []
        
        for l in current {
            
            // because we are going sequentially through this looking for large to small, it is safe to not worry about previously spent tokens
            if leftToFind > 0 {
                if l.value! <= leftToFind {
                    leftToFind -= l.value!
                    l.id = nil
                    l.height = nil
                    l.date = UInt64(consensusTime())
                    l.transaction_id = Data(bytes:UUID().uuidString.sha512().bytes.sha224())
                    l.transaction_ref = ref
                    l.source = owner
                    l.destination = destination
                    l.op = LedgerOPType.ChangeOwner.rawValue
                    l.hash = l.signatureHash()
                    pay_tokens.append(l)
                }
            }
        }
        
        // now we look for the fee, but we can't pick anything already in the pay array
        
        for l in current {
            
            // because we are going sequentially through this looking for large to small, it is safe to not worry about previously spent tokens
            if leftToFee > 0 {
                if l.value! <= leftToFee {
                    
                    // now check it's not been used already
                    var found = false
                        for t in pay_tokens {
                            if t.id == l.id {
                                found = true
                            }
                        }
                    
                    if !found {
                        leftToFee -= l.value!
                        l.transaction_ref = ref
                        l.transaction_id = Data(bytes:UUID().uuidString.sha512().bytes.sha224())
                        l.id = nil
                        l.height = nil
                        l.date = UInt64(consensusTime())
                        if Config.CommunityAddress != nil {
                            l.destination = Crypto.strAddressToData(address: Config.CommunityAddress!)
                            l.source = owner
                            l.op = LedgerOPType.ChangeOwner.rawValue
                            l.hash = l.signatureHash()
                            fee_tokens.append(l)
                        }
                    }
                }
            }
        }
        
        if leftToFee > 0 || leftToFind > 0 {
            return nil
        }
        
        let newTransfer = TransferRequest()
        newTransfer.fee = fee_tokens
        newTransfer.tokens = pay_tokens
        
        return newTransfer
        
    }
    
    func CurrentlyOwnedTokens(address: Data) -> [Ledger] {
        
        var retValue: (allocations: [Ledger], spends: [Ledger]) = ([],[])
        
        blockchain_lock.mutex {
            retValue = Database.WalletAddressContents(address: address)
        }

        let maxHeight = Block.currentNetworkBlockHeight()
        let allocation = retValue.allocations
        let spends = retValue.spends
        var current_tokens: [Ledger] = []
        
        // aggregate together all of the allocations, which have not been spent
        for alloc in allocation {
            
            var found = false
            for spend in spends {
                if alloc.destination == spend.source && alloc.ore == spend.ore && alloc.address == spend.address {
                    found = true
                    break
                }
            }
            
            if !found {
                if alloc.height! <= maxHeight {
                    current_tokens.append(alloc)
                }
            }
            
        }
        
        return current_tokens
        
    }
    
    func WalletAddressContents(address: Data) -> WalletAddress {
        
        var retValue: (allocations: [Ledger], spends: [Ledger]) = ([],[])
        
        blockchain_lock.mutex {
            retValue = Database.WalletAddressContents(address: address)
        }
        
        let w = WalletAddress()
        let maxHeight = Block.currentNetworkBlockHeight()
        let allocation = retValue.allocations
        let spends = retValue.spends
        var current_tokens: [Ledger] = []
        
        // aggregate together all of the allocations, which have not been spent
        for alloc in allocation {
            
            var found = false
            for spend in spends {
                if alloc.destination == spend.source && alloc.ore == spend.ore && alloc.address == spend.address {
                    found = true
                    break
                }
            }
            
            if w.current_balance == nil {
                w.current_balance = 0
            }
            
            if w.pending_balance == nil {
                w.pending_balance = 0
            }
            
            if !found {
                if alloc.height! <= maxHeight {
                    w.current_balance! += alloc.value!
                } else {
                    w.pending_balance! += alloc.value!
                }
                current_tokens.append(alloc)
            }
            
        }
        
        // create an incoming and outgoing dictionary
        var incoming: [Data:Int] = [:]
        var outgoing: [Data:Int] = [:]
        var incoming_pending: [Data:Int] = [:]
        var outgoing_pending: [Data:Int] = [:]
        
        for c in current_tokens {
            if c.op! == LedgerOPType.ChangeOwner.rawValue {
                if c.height! <= maxHeight {
                    if incoming[c.transaction_ref!] == nil {
                        incoming[c.transaction_ref!] = c.value ?? 0
                    } else {
                        incoming[c.transaction_ref!]! += c.value ?? 0
                    }
                } else {
                    if incoming_pending[c.transaction_ref!] == nil {
                        incoming_pending[c.transaction_ref!] = c.value ?? 0
                    } else {
                        incoming_pending[c.transaction_ref!]! += c.value ?? 0
                    }
                }
            }
        }
        
        for s in spends {
            if s.op! == LedgerOPType.ChangeOwner.rawValue {
                if s.height! <= maxHeight {
                    if outgoing[s.transaction_ref!] == nil {
                        outgoing[s.transaction_ref!] = s.value ?? 0
                    } else {
                        outgoing[s.transaction_ref!]! += s.value ?? 0
                    }
                } else {
                    if outgoing_pending[s.transaction_ref!] == nil {
                        outgoing_pending[s.transaction_ref!] = s.value ?? 0
                    } else {
                        outgoing_pending[s.transaction_ref!]! += s.value ?? 0
                    }
                }
            }
        }
        
        for c in current_tokens {
            if c.op! == LedgerOPType.ChangeOwner.rawValue {
                if incoming[c.transaction_ref!] != nil {
                    let t = WalletTransfer()
                    t.destination = c.destination
                    t.ref = c.transaction_ref
                    t.date = c.date
                    t.total = incoming[c.transaction_ref!]
                    t.source = c.source
                    w.incoming.append(t)
                    incoming.removeValue(forKey: c.transaction_ref!)
                }
                if incoming_pending[c.transaction_ref!] != nil {
                    let t = WalletTransfer()
                    t.destination = c.destination
                    t.ref = c.transaction_ref
                    t.date = c.date
                    t.total = incoming_pending[c.transaction_ref!]
                    t.source = c.source
                    w.incoming_pending.append(t)
                    incoming_pending.removeValue(forKey: c.transaction_ref!)
                }
            }
        }
        
        for c in spends {
            if c.op! == LedgerOPType.ChangeOwner.rawValue {
                if outgoing[c.transaction_ref!] != nil {
                    let t = WalletTransfer()
                    t.destination = c.destination
                    t.ref = c.transaction_ref
                    t.date = c.date
                    t.total = outgoing[c.transaction_ref!]
                    t.source = c.source
                    w.outgoing.append(t)
                    outgoing.removeValue(forKey: c.transaction_ref!)
                }
                if outgoing_pending[c.transaction_ref!] != nil {
                    let t = WalletTransfer()
                    t.destination = c.destination
                    t.ref = c.transaction_ref
                    t.date = c.date
                    t.total = outgoing_pending[c.transaction_ref!]
                    t.source = c.source
                    w.outgoing_pending.append(t)
                    outgoing_pending.removeValue(forKey: c.transaction_ref!)
                }
            }
        }
        
        return w
        
    }
    
    func WalletAddressSummary(address: Data) -> WalletAddress {
        
        var retValue = WalletAddress()
        
        blockchain_lock.mutex {
            retValue = Database.WalletAddressSummary(address: address)
        }
        
        return retValue
        
    }
    
    func HashForBlock(_ height: Int) -> Data {
        
        var ledgerHash: Data = Data()
        
        blockchain_lock.mutex {
            ledgerHash = Database.HashesForBlock(height)
        }
        
        return ledgerHash
        
    }
    
    func addBlock(_ block:Block) -> Bool {
        
        var retValue = false
        
        blockchain_lock.mutex {
            
            if block.height! > self.height() {
                retValue = Database.WriteBlock(block)
                if retValue {
                    self.setNewHeight(Int(block.height!))
                }
            }
            
        }
        
        return retValue
        
    }

    
    // ledger functions
    
    func commitLedgerItems(tokens: [Ledger], failIfAny: Bool, op: LedgerOPType) -> Bool {
        
            var retValue = true
            
            blockchain_lock.mutex {
                
                if Database.CommitLedger(ledgers: tokens, failAll: failIfAny, op: op) {
                    
                    retValue = true
                    
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
                l = Database.TokenOwnershipRecord(ore: t.oreHeight, address: t.address)
            }

        } catch {
            return []
        }
        
        return l;
        
    }
    
    func registerToken(tokenString: String, address: String, block: Int) throws -> Bool {
        
        let token = tokenString
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
        
        if AlgorithmManager.sharedInstance().depricated(type: t!.algorithm, height: UInt(t!.oreHeight)) {
            logger.log(level: .Debug, log: "(BlockChain) token submitted to 'registerToken(token: String, address: String, block: Int) -> Bool' was of deprecated method.")
            throw BlockchainErrors.InvalidAlgo
        }
        
        // create the ledger
        let l = Ledger()
        l.op = LedgerOPType.RegisterToken.rawValue
        l.address = t!.address
        l.height = block
        l.algorithm = t!.algorithm.rawValue
        l.date = UInt64(consensusTime())
        l.destination = Crypto.strAddressToData(address: address)
        l.ore = t!.oreHeight
        l.transaction_id = Data(bytes: UUID().uuidString.sha512().bytes.sha224())
        l.source = Crypto.strAddressToData(address: address)
        l.value = t!.value()
        l.hash = l.signatureHash()
        var success = false;
        
        // the atomicity & validity of the ledger will be checked by the data layer upon submission
        blockchain_lock.mutex {
            success = Database.CommitLedger(ledgers: [l], failAll: true, op: .RegisterToken)
        }
        
        if success {
            
            logger.log(level: .Info, log: "Token submitted with address '\(l.address!.toHexString())' succeeded, token written.")
            
            // now broadcast this transaction to the connected nodes
            broadcaster.add([l], atomic: true, op: .RegisterToken)
            
            return true
            
        } else {
            
            if t!.value() == 0 {
                logger.log(level: .Debug, log: "Token submitted with address '\(l.address!.toHexString())' was invalid and has no value.")
                throw BlockchainErrors.TokenHasNoValue
            }
            
            logger.log(level: .Debug, log: "Token submitted with address '\(l.address!.toHexString())' failed, this token exists already in blockchain.db")
            
        }
        
        return false
        
    }
    
    
}
