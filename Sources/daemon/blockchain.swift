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

class BlockChain {
    
    private let lock: Mutex
    private var blocks_cache: [UInt32:Block] = [:]
    private var current_tidemark: Block?
    
    init() {
        
        lock = Mutex()
        
    }
    
    func height() -> UInt32 {
        
        var count: UInt32 = 0
        
        lock.mutex {
            
            // query the database to find the highest block there is
            count = Database.CurrentHeight()!
            
        }
        
        return count
        
    }
    
    func blockAtHeight(_ height: UInt32) -> Block? {
        
        var block: Block? = nil
        
        lock.mutex {
            
            // check the cache first, then query the database
            if blocks_cache[height] != nil {
                block = blocks_cache[height]
            } else {
                
                // query database
                block = Database.BlockAtHeight(height)
                
            }
            
        }
        
        return block
        
    }
    
    func addBlock(_ block:Block) {
        
        lock.mutex {
            
            blocks_cache[block.height] = block
            
        }
        
    }
    
    func oreSeeds() -> [Block] {
        
        var retValue: [Block] = []
        
        lock.mutex {
            retValue = Database.OreBlocks()
            
        }
        
        return retValue
        
    }
    
    // ledger functions
    
    func registerToken(token: String, address: String, block: UInt32) -> Bool {
        
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
                
                let l = Ledger(op: .RegisterToken, token: token, ref: UUID().uuidString, address: address, auth: "", block: block)
                if Database.WritePendingLedger(l) == true {
                    returnValue = true
                }
                
            }
            
        }
        
        return returnValue
        
    }
    
    
}