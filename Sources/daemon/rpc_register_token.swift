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

class RPCRegisterToken {
    
    class func action(_ payload: [String:Any?]) throws -> [String:Any?] {
        
        if payload["token"] == nil {
            throw RPCErrors.InvalidRequest
        }
        
        if payload["address"] == nil {
            throw RPCErrors.InvalidRequest
        }
        
        if payload["block"] == nil {
            throw RPCErrors.InvalidRequest
        }
        
        // setup the variables
        
        let token = payload["token"] as! String
        let address = payload["address"] as! String
        let block = payload["block"] as! UInt32
        
        if blockchain.registerToken(token: token, address: address, block: block) {
            
            return ["success" : true, "token" : token, "block" : block]
            
        } else {
            
            throw RPCErrors.InvalidRequest
            
        }
        
    }
    
}
