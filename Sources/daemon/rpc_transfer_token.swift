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

class RecieveTransfer {
    
    class func action(_ tr: TransferRequest, block: Int) throws {
        
        if tr.tokens.count == 0 {
            throw RPCErrors.InvalidRequest
        }
        
        for t in tr.tokens {
            t.height = block
            t.id = nil
        }
        
        // if this is the entry point into the system for this transaction, then we need to allocate ids
        for t in tr.tokens {
            if t.transaction_id == nil {
                throw RPCErrors.InvalidRequest
            }
        }
        
        // we ask the data layer to check that every single one of the tokens one-by-one, then transfer.  A boolean is returned to indicate success or failure.
        if blockchain.commitLedgerItems(tokens: tr.tokens, failIfAny: true, op: .ChangeOwner) {
            
            logger.log(level: .Info, log: "Transfer request from VE\(tr.tokens[0].destination!.bytes.base58EncodedString) to VE\(tr.tokens[0].source!.bytes.base58EncodedString) of \(tr.tokens.count) objects.")
            
            // distribute this transfer to other nodes
            broadcaster.add(tr.tokens, atomic: true, op: .ChangeOwner)
            
        } else {
            
            throw RPCErrors.InvalidRequest
            
        }
        
        if blockchain.commitLedgerItems(tokens: tr.fee, failIfAny: true, op: .ChangeOwner) {
            
            logger.log(level: .Info, log: "Transfer request from VE\(tr.tokens[0].destination!.bytes.base58EncodedString) paid it's dues into the community fund.")
            
            // distribute this transfer to other nodes
            broadcaster.add(tr.tokens, atomic: true, op: .ChangeOwner)
            
        } else {
            
            throw RPCErrors.InvalidRequest
            
        }
        
    }
    
}
