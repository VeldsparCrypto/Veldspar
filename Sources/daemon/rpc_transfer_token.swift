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
    
    class func action(_ jsonBody: String) throws -> String {
        
        let decoder = JSONDecoder()
        decoder.dataDecodingStrategy = .base64
        
        let request = try? decoder.decode(TransferRequest.self, from: jsonBody.data(using: .ascii)!)
        if request == nil {
            throw RPCErrors.InvalidRequest
        }
        
        var tr = request!
        
        if tr.tokens.count == 0 {
            throw RPCErrors.InvalidRequest
        }
        
        // check the digital signatures
        for t in tr.tokens {
            if !t.verifySignature() {
                throw RPCErrors.InvalidRequest
            }
        }
        
        let estimatedTarget = (blockchain.height() + Config.TransactionMaturityLevel)
        
        var tokens = tr.tokens
        for t in tokens {
            t.height = estimatedTarget
        }
        
        // so the request is valid, now to make sure the tokens are owned by the requester and they are free to be transfered
        
        // we ask the data layer to check that every single one of the tokens one-by-one, then transfer.  A boolean is returned to indicate success or failure.
        
        if blockchain.transferOwnership(request: transferRequest) {
            
            // distribute this transfer to other nodes
            
            
        } else {
            
            throw RPCErrors.InvalidRequest
            
        }
        
        return ""
        
    }
    
}
