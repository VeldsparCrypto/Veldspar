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
    
    var lock: Mutex = Mutex()
    var currentBlockData: Data?
    var inProgress = false
    
    func currentNetworkBlockHeight() -> Int {
        let currentTime = consensusTime()
        return Int((currentTime - Config.BlockchainStartDate) / (Config.BlockTime * 1000))
    }
    
    func Loop() {
        
        // sleep for 5 minutes, waiting for nodes to transmit the missing transactions to the server before producing a block
        if settings.isSeedNode {
            logger.log(level: .Info, log: "Waiting for other nodes to send outstanding transactions before continuing to produce blocks.")
            Thread.sleep(forTimeInterval: 30)
            logger.log(level: .Info, log: "Updates recieved, starting the production of blocks.")
        }
        
        while true {
            
            if !inProgress {
                queueBlockProductionIfRequired()
            }
            
        }
        
    }
    
    func validateNewBlockWithNetwork(_ newBlock: Block) {
        
        let currentNWHeight = Block.currentNetworkBlockHeight()
        var behind = false
        if (currentNWHeight - newBlock.height!) > 2 {
            behind = true
        }
        
        if !behind {
            logger.log(level: .Info, log: "Generated block @ height \(newBlock.height!) with hash \(newBlock.hash!.toHexString().lowercased())")
        }
        
        if !settings.isSeedNode {
            
            var agreement: Float = 0.0
            var responses: Float = 0.0
            var attempts = 0
            
            if !behind {
                
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
                
            }
            
            // check the level of quorum
            var quorum = Float(0.0)
            if !behind && responses > 0.0 {
                quorum = agreement / responses
            }
            if behind || quorum < 1.0 {
                
                if !behind {
                    // logger.log(level: .Warning, log: "Block signature verification failed, attempting to re-sync block data with network")
                }
                
                // something we have is either missing or extra :(.  Ask the authoritive node for all of the transactions for a certain height
                var authoritiveBlockData = comms.blockDataAtHeight(height: newBlock.height!)
                
                if authoritiveBlockData == nil {
                    // unable to get the block data from the seed node, wait and try again
                    if !behind {
                        //logger.log(level: .Warning, log: "Network failed to return block data, waiting 30 seconds and trying again.")
                    }
                    Thread.sleep(forTimeInterval: 30.0)
                    authoritiveBlockData = comms.blockDataAtHeight(height: newBlock.height!)
                }
                
                if authoritiveBlockData == nil {
                    
                    if !behind {
                        logger.log(level: .Warning, log: "Network not available to confirm block signature.")
                    }
                
                    lock.mutex {
                        self.currentBlockData = nil;
                        self.inProgress = false
                    }
                
                } else {
                    
                    // we have the authoritive block data, so poop-can the current block data and re-write it with the new.
                    _ = blockchain.removeBlockAtHeight(newBlock.height!)
                    
                    lock.mutex {
                        self.currentBlockData = authoritiveBlockData
                    }
                    
                    // inflate the block data back into an object
                    let o = try? JSONDecoder().decode(Block.self, from: authoritiveBlockData!)
                    
                    if o != nil {
                        
                        if !behind {
                            logger.log(level: .Info, log: "Writing block \(o!.height!) into blockchain with signature \(o!.hash!.toHexString().lowercased())")
                        } else {
                            
                            // show the catch up message
                            let targetHeight = Block.currentNetworkBlockHeight()
                            let current = o!.height!
                            
                            // calculate the diff in Block Time
                            let behind = targetHeight - current
                            let seconds = behind * Config.BlockTime
                            
                            let dhm: (days: String, hours: String, minutes: String) = (String((seconds / 86400)), String((seconds % 86400) / 3600),String((seconds % 3600) / 60))
                            
                            logger.log(level: .Info, log: "Block \(o!.height!) downloaded from seed node(s), node is \(dhm.days)d \(dhm.hours)h \(dhm.minutes)m behind network")
                            
                        }
                        _ = blockchain.addBlock(o!)
                        
                        // dispatch the finalise closure
                        Execute.background {
                             self.finalise(newBlock.height!)
                        }
                        
                    } else {
                        
                        lock.mutex {
                            self.currentBlockData = nil;
                            self.inProgress = false
                        }
                        
                    }
                    
                }
                
            } else {
                
                logger.log(level: .Info, log: "Writing block \(newBlock.height!) into blockchain with signature \(newBlock.hash!.toHexString().lowercased())")
                _ = !blockchain.addBlock(newBlock)
                
                // dispatch the finalise closure
                Execute.background {
                    
                    if settings.blockchain_export_data {
                        
                        let b = blockchain.blockAtHeight(newBlock.height!, includeTransactions: true)
                        let d = try? JSONEncoder().encode(b)
                        if d != nil {
                            self.lock.mutex {
                                self.currentBlockData = d
                            }
                        }
                        
                        Execute.background {
                            self.finalise(newBlock.height!)
                        }
                        
                    } else {
                        
                        Execute.background {
                            self.finalise(newBlock.height!)
                        }
                        
                    }
                    
                }
                
            }
            
        } else {
            
            // this is a/the seed node, so just write this (until we go for quorum model in v0.2.0)
            logger.log(level: .Info, log: "Writing block \(newBlock.height!) into blockchain with signature \(newBlock.hash!.toHexString().lowercased())")
            
            _ = blockchain.addBlock(newBlock)
            
            // dispatch the finalise closure
            Execute.background {
                
                if settings.blockchain_export_data {
                    
                    let b = blockchain.blockAtHeight(newBlock.height!, includeTransactions: true)
                    let d = try? JSONEncoder().encode(b)
                    if d != nil {
                        self.lock.mutex {
                            self.currentBlockData = d
                        }
                    }
                    
                    Execute.background {
                        self.finalise(newBlock.height!)
                    }
                    
                } else {
                    
                    Execute.background {
                        self.finalise(newBlock.height!)
                    }
                    
                }

            }
            
        }
        
    }
    
    func generateHashForBlock(_ height: Int) {
    
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
        
        Execute.background {
            self.validateNewBlockWithNetwork(newBlock)
        }
    
    }
    
    func makeNextBlock() {
        
        let height = Int(blockchain.height()+1)
        Execute.background {
            self.generateHashForBlock(height)
        }
        
    }
    
    func queueBlockProductionIfRequired() {
        
        let currentTime = consensusTime()
        if currentTime > Config.BlockchainStartDate {
            
            lock.mutex {
                
                if inProgress == false {
                    
                    let currentTime = consensusTime()
                    if currentTime > Config.BlockchainStartDate {
                        
                        // get the current height, and work out which block should be created and when
                        let blockHeightForTime = currentNetworkBlockHeight()
                        
                        if blockchain.height() < blockHeightForTime {
                            
                            inProgress = true
                            
                            // blocks are required, now dispatch the activity
                            Execute.background {
                                self.makeNextBlock()
                            }
                            
                        }
                    }
                }
            }
        }
        
    }
    
    func finalise(_ height: Int) {
        
        if settings.blockchain_export_data {
            
            try? FileManager.default.createDirectory(atPath: "./cache/blocks", withIntermediateDirectories: true, attributes: [:])
            let filePath = "./cache/blocks/\(height).block"
            
            lock.mutex {
                
                if self.currentBlockData != nil {
                    do {
                        try self.currentBlockData!.write(to: URL(fileURLWithPath: filePath))
                    } catch {
                        logger.log(level: .Error, log: "Failed to export block \(height), error = '\(error)'")
                    }
                }
                self.currentBlockData = nil
                
                // if we are in here, then this is the end point and we need to unlock the block production
                
            }
            
        }
        
        lock.mutex {
            self.inProgress = false
        }
        
    }
    
}
