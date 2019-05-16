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

// this class is a background thread which constantly monitors the time, and creates new blocks when required, checks quorum, and queries other nodes to make sure we posess all of the transactions and none are missed.

class BlockMaker {
    
    enum BlockmakerErrors : Error {
        case NotDue
        case NotAvailable
        case Done
    }
    
    func currentNetworkBlockHeight() -> Int {
        let currentTime = consensusTime()
        return Int((currentTime - Config.BlockchainStartDate) / (Config.BlockTime * 1000))
    }
    
    func makeUrlRequest(url: URL) throws -> URLRequest {
        var rq = URLRequest(url: url)
        rq.httpMethod = "GET"
        return rq
    }
    
    init() {
        
        Execute.background {
            
            // sleep for 5 minutes, waiting for nodes to transmit the missing transactions to the server before producing a block
            if settings.isSeedNode {
                logger.log(level: .Info, log: "Waiting for other nodes to send outstanding transactions before continuing to produce blocks.")
                Thread.sleep(forTimeInterval: 30)
                logger.log(level: .Info, log: "Updates recieved, starting the production of blocks.")
            }
            
            self.run()
            
        }
        
    }
    
    func run() {
        
        
        do {
            try makeNextBlock()
        } catch BlockmakerErrors.NotAvailable {
            Thread.sleep(forTimeInterval: 5)
        } catch BlockmakerErrors.NotDue {
            Thread.sleep(forTimeInterval: 1)
        } catch BlockmakerErrors.Done {
            // do nothing, get onto the next block as quickly as possible 
        } catch {
            Thread.sleep(forTimeInterval: 0.2)
        }
        
        Execute.background {
            self.run()
        }
        
    }
    
    func makeNextBlock() throws {
        
        let currentTime = consensusTime()
        if currentTime < Config.BlockchainStartDate {
            throw BlockmakerErrors.NotDue
        }
        
        var height = blockchain.height()
        let nwHeight = Block.currentNetworkBlockHeight()
        
        if height >= nwHeight {
            throw  BlockmakerErrors.NotDue
        }
        
        // work out if we are behind or not?
        var behind = false
        if (nwHeight - height) > 2 {
            behind = true
        }
        
        height += 1
        
        // making a new block
        // produce the block, hash it, seek quorum, then write it
        let previousBlock = blockchain.blockAtHeight(height-1, includeTransactions: false)
        
        var newBlock = Block()
        newBlock.height = height
        
        var newHash = Data()
        newHash.append(previousBlock?.hash ?? Data())
        newHash.append(contentsOf: height.toHex().bytes)
        newHash.append(blockchain.HashForBlock(height))
        newBlock.hash = newHash.sha224()
        newBlock.transactions = []
        
        if settings.isSeedNode {
            
            // this is a/the seed node, so just write this (until we go for quorum model in v0.2.0)
            logger.log(level: .Info, log: "Writing block \(newBlock.height!) into blockchain with signature \(newBlock.hash!.toHexString().lowercased())")
            
            _ = blockchain.addBlock(newBlock)
            
            if settings.blockchain_export_data {
                
                Execute.background {
                    let d = try? JSONEncoder().encode(newBlock)
                    
                    try? FileManager.default.createDirectory(atPath: "./cache/blocks", withIntermediateDirectories: true, attributes: [:])
                    let filePath = "./cache/blocks/\(height).block"
                    
                    do {
                        try d!.write(to: URL(fileURLWithPath: filePath))
                    } catch {
                        logger.log(level: .Error, log: "Failed to export block \(height), error = '\(error)'")
                    }
                }
                
            }
            
            throw  BlockmakerErrors.Done
            
        } else if !behind {
            
            // normal node, seek quorum
            var agreement: Float = 0.0
            var responses: Float = 0.0
            var attempts = 0
            
            // now contact the seed node(s) to get their hashes
            var nodes = Config.SeedNodes
            if isTestNet {
                nodes = Config.TestNetNodes
            }
            
            while true {
                for n in nodes {
                    let blockHash = comms.hashForBlock(address: n, height: newBlock.height!)
                    if blockHash != nil {
                        if blockHash!.ready! {
                            responses += 1.0
                            if blockHash?.hash == newBlock.hash {
                                agreement += 1.0
                            } else {
                                
                            }
                        } else {
                            // seed block is not ready yet, do nothing, because we will re-try after a delay
                        }
                    } else {
                        // timeout, or error.  Do nothing, because it will be covered in a retry
                    }
                }
                if responses == 1.0 {
                    break
                }
                if attempts == 480 {
                    logger.log(level: .Error, log: "Unable to communicate with network for 240 mins, exiting as impossible to verify block image.")
                    exit(1)
                }
                attempts += 1
                logger.log(level: .Warning, log: "Failed to seek agreement for block hash with the network, will retry in 30 seconds.")
                Thread.sleep(forTimeInterval: 30)
            }
            
            // check the level of quorum
            var quorum = Float(0.0)
            if !behind && responses > 0.0 {
                quorum = agreement / responses
            }
            if quorum < 1.0 {
                
                // go get the authoritive block
                behind = true
                
            } else {
                
                logger.log(level: .Info, log: "Writing block \(newBlock.height!) into blockchain with signature \(newBlock.hash!.toHexString().lowercased())")
                _ = !blockchain.addBlock(newBlock)
                
                if settings.blockchain_export_data {
                    
                    Execute.background {
                        let d = try? JSONEncoder().encode(newBlock)
                        
                        try? FileManager.default.createDirectory(atPath: "./cache/blocks", withIntermediateDirectories: true, attributes: [:])
                        let filePath = "./cache/blocks/\(height).block"
                        
                        do {
                            try d!.write(to: URL(fileURLWithPath: filePath))
                        } catch {
                            logger.log(level: .Error, log: "Failed to export block \(height), error = '\(error)'")
                        }
                    }
                    
                }
                
                throw  BlockmakerErrors.Done
                
            }
            
        }
        
        if behind {
            
            // just go and get an authoritive block
            // something we have is either missing or extra :(.  Ask the authoritive node for all of the transactions for a certain height
            let authoritiveBlockData = comms.blockDataAtHeight(height: height)
            
            if authoritiveBlockData == nil {
                throw  BlockmakerErrors.NotAvailable
            }
            
            // we have the authoritive block data, so poop-can the current block data and re-write it with the new.
            _ = blockchain.removeBlockAtHeight(height)
            
            // inflate the block data back into an object
            let o = try? JSONDecoder().decode(Block.self, from: authoritiveBlockData!)
            
            if o != nil {
                
                // show the catch up message
                let targetHeight = Block.currentNetworkBlockHeight()
                let current = o!.height!
                
                // calculate the diff in Block Time
                let behind = targetHeight - current
                let seconds = behind * Config.BlockTime
                
                let dhm: (days: String, hours: String, minutes: String) = (String((seconds / 86400)), String((seconds % 86400) / 3600),String((seconds % 3600) / 60))
                
                logger.log(level: .Info, log: "Block \(o!.height!) downloaded from seed node(s), node is \(dhm.days)d \(dhm.hours)h \(dhm.minutes)m behind network")
                _ = blockchain.addBlock(o!)
                
                if settings.blockchain_export_data {
                    
                    Execute.background {
                        try? FileManager.default.createDirectory(atPath: "./cache/blocks", withIntermediateDirectories: true, attributes: [:])
                        let filePath = "./cache/blocks/\(height).block"
                        
                        do {
                            try authoritiveBlockData!.write(to: URL(fileURLWithPath: filePath))
                        } catch {
                            logger.log(level: .Error, log: "Failed to export block \(height), error = '\(error)'")
                        }
                    }
                    
                }
                
                throw  BlockmakerErrors.Done
                
            } else {
                
                throw  BlockmakerErrors.NotAvailable
                
            }
            
        }
        
    }
    
}
