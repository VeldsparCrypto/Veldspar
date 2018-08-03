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

class RPCTransferToken {
    
    class func action(_ payload: [String:Any?]) throws -> [String:Any?] {
        
        if payload["token"] == nil {
            throw RPCErrors.InvalidRequest
        }
        
        if payload["address"] == nil {
            throw RPCErrors.InvalidRequest
        }
        
        if payload["auth"] == nil {
            throw RPCErrors.InvalidRequest
        }
        
        if payload["reference"] == nil {
            throw RPCErrors.InvalidRequest
        }
        
        // setup the variables
        
        let token = payload["token"] as! String
        let address = payload["address"] as! String
        let auth = payload["auth"] as! String
        let reference = payload["reference"] as! String
        let block = blockchain.height() + UInt32(Config.TransactionMaturityLevel)
        
        // get the current ownership details of the token
        let current = blockchain.tokenLedger(token: token)
        if current == nil { // not a registered token, or maturity level not reached, it can't be transferred
            throw RPCErrors.InvalidRequest
        }
        
        // check that the token is not currently the subject of an existing transfer
        let pending = blockchain.tokenLedger(token: token)
        if pending != nil { // token is already a pending transaction
            throw RPCErrors.InvalidRequest
        }
        
        // check that the request has the authority to transfer the token by testing the public key signature
        let transferSignature = Crypto.makeTransactionSignature(src: current!.destination, dest: address, token: token)
        if Crypto.isSigned(transferSignature, signature: auth, address: current!.destination) {
            // signatures match, time to add this to the pending chain
            
            if blockchain.transferToken(token: token, address: address, block: block, auth: auth, reference: reference) {
                
                return ["success" : true, "token" : token, "block" : block]
                
            } else {
                
                throw RPCErrors.InvalidRequest
                
            }
            
        } else {
            throw RPCErrors.InvalidRequest
        }
        
        
        
    }
    
}
