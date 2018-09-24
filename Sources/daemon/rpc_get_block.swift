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
class RPCGetBlock {
    
    class func action(_ height: Int) -> RPC_Block {
        
        let rpcBlock = RPC_Block()
        
        let b = blockchain.blockAtHeight(height)
        if b != nil {
            
            rpcBlock.hash = b?.hash
            rpcBlock.height = b?.height
            rpcBlock.seed = b?.oreSeed
            
            for l in b?.transactions ?? [] {
                
                let ledger = RPC_Ledger()
                ledger.height = l.height
                ledger.date = l.date
                ledger.destination = l.destination
                ledger.op = l.op.rawValue
                ledger.auth = l.auth
                ledger.location = l.location
                ledger.transaction_ref = l.transaction_ref
                ledger.transaction_id = l.transaction_id

                rpcBlock.transactions.append(ledger)
                
            }
            
        } else {
            
        }
        
        return rpcBlock
        
    }
    
}
