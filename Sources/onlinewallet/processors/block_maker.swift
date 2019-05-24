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
            
            self.run()
            
        }
        
    }
    
    func run() {
        
        do {
            try makeNextBlock()
        } catch BlockmakerErrors.NotAvailable {
            Thread.sleep(forTimeInterval: 10)
        } catch BlockmakerErrors.NotDue {
            Thread.sleep(forTimeInterval: 1)
        } catch BlockmakerErrors.Done {
            // do nothing, get onto the next block as quickly as possible
        } catch {
            Thread.sleep(forTimeInterval: 0.2)
        }
        
        Execute.backgroundAfter(after: 0.1, {
            self.run()
        })
        
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
        height += 1
        
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
            
            throw  BlockmakerErrors.Done
            
        } else {
            
            throw  BlockmakerErrors.NotAvailable
            
        }
        
    }
    
}
