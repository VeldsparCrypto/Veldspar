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

class Broadcaster {
    
    var isBroadcasting = false
        
    func  add(_ ledgers: [Ledger], atomic: Bool, op: LedgerOPType) {
        
        let l = Ledgers()
        l.atomic = atomic
        l.broadcastId = UUID().uuidString.lowercased()
        l.source_nodeId = thisNode.nodeId
        l.visitedNodes = []
        l.transactions = []
        l.transactions.append(contentsOf: ledgers)
        l.op = op.rawValue
        
        // throw this transaction into the temp cache manager now on background thread
        Execute.background {
            
            let d = try? JSONEncoder().encode(l)
            if d != nil {
                tempManager.putBroadcastOut(d!)
                var seedNodes = Config.SeedNodes
                if isTestNet {
                    seedNodes = Config.TestNetNodes
                }
                for n in seedNodes {
                    tempManager.putBroadcastOutSeed(d!, seed: n)
                }
            }
            
        }
        
    }
    
}
