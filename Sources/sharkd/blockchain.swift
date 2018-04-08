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
import SharkCore

class BlockChain {
    
    private let lock: Mutex
    private var blocks_cache: [UInt64:Block] = [:]
    private var current_tidemark: Block?
    
    init() {
        
        lock = Mutex()
        
    }
    
    func height() -> UInt64 {
        
        var count: UInt64 = 0
        
        lock.mutex {
            
            // query the database to find the highest block there is
            
        }
        
        return count
        
    }
    
    func tidemark() -> UInt64 {
        
        var count: UInt64 = 0
        
        lock.mutex {
            
            // query the database to find the highest block there is, and return it's timestamp
            if current_tidemark != nil {
                count = current_tidemark!.LatestTimestamp()
            }
            
        }
        
        return count
        
    }
    
    func blockAtHeight(_ height: UInt64) -> Block? {
        
        var block: Block? = nil
        
        lock.mutex {
            
            // check the cache first, then query the database
            if blocks_cache[height] != nil {
                block = blocks_cache[height]
            } else {
                
                // query database
                
                
            }
            
        }
        
        return block
        
    }
    
    func addBlock(_ block:Block) {
        
        lock.mutex {
            
            blocks_cache[block.height] = block
            
            
            
        }
        
    }
    
    func returnWallet(wallet: Wallet) {
        lock.mutex {
            wallet.putBack()
        }
    }
    
    
}
