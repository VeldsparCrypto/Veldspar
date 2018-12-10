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

class InterNodeTransferProcessor {
    
    init() {
        
        InterNodeTransferProcessor.processNext()
        
    }
    
    class func processNext() {
        
        Execute.background {
            
            let int = tempManager.popIntInbound()
            if int != nil {
                
                // decode this and process it
                // decode the ledgers object
                let l = try? JSONDecoder().decode(Ledgers.self, from: int!)
                
                if l != nil {
                    
                    // check to see if this transaciton is too old and dump it.
                    if l!.transactions.count > 0 {
                        
                        if l!.source_nodeId == thisNode.nodeId {
                            // throw this away as this is an internal transfer
                            InterNodeTransferProcessor.processNext()
                            return
                        }
                        
                        if l!.transactions[0].height == nil || l!.transactions[0].height! >= blockchain.height() {
                            // the transaction is too old so that's it for this i-n-t
                            InterNodeTransferProcessor.processNext()
                            return
                        }
                        
                        if l!.atomic {
                            // throw these ledgers to the blockchain as they will be verified later on
                            _ = blockchain.commitLedgerItems(tokens: l!.transactions, failIfAny: true)
                        } else {
                            // throw these ledgers to the blockchain as they will be verified later on
                            _ = blockchain.commitLedgerItems(tokens: l!.transactions, failIfAny: false)
                        }
                        InterNodeTransferProcessor.processNext()
                        
                    }

                }

            } else {
                Execute.backgroundAfter(after: 1.0, {
                    InterNodeTransferProcessor.processNext()
                })
            }
            
        }
        
    }
    
}
