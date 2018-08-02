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
import Foundation
import PerfectHTTP
import VeldsparCore

enum RPCErrors : Error {
    case InvalidRequest
    case DuplicateRequest
}

func handleRequest() throws -> RequestHandler {
    return {
        
        request, response in
        
        let body = request.postBodyString ?? ""
        var json: JSON = JSON.null
        if body != "" {
            json = try! JSON(data: body.data(using: .utf8, allowLossyConversion: false)!)
        }
        let payload = json.dictionaryObject
        
        response.setHeader(.contentType, value: "application/json")
        response.setHeader(.accessControlAllowOrigin, value: "*")
        response.setHeader(.accessControlAllowMethods, value: "GET, POST, PATCH, PUT, DELETE, OPTIONS")
        response.setHeader(.accessControlAllowHeaders, value: "Origin, Content-Type, X-Auth-Token")
        
        if request.method == .get {
            
            do {
                
                if request.path == "/" {
                    try response.setBody(json: ["Server" : "\(Config.CurrencyName) Node", "version" : "\(Config.Version)"])
                }
                
                if request.path == "/info/timestamp" {
                    try response.setBody(json: ["timestamp" : UInt64(Date().timeIntervalSince1970*1000)])
                }
                
                if request.path == "/blockchain/currentheight" {
                    try response.setBody(json: ["height" : blockchain.height()])
                }
                
                if request.path == "/blockchain/seeds" {
                    try response.setBody(json: RPCOreSeeds.action())
                }
                
                if request.path == "/blockchain/ledger" {
                    
                    // query the ledger at a specific height, and return the transactions.  Used for wallet implementations
                    
                    
                    
                }
                
            } catch {
                
                
                
            }
            
            
            
        } else if request.method == .post {
            
            do {
                
                if payload != nil {
                    
                    if request.path == "/token/register" {
                        try response.setBody(json: RPCRegisterToken.action(payload!))
                    }
                    
                    if request.path == "/token/transfer" {
                        try response.setBody(json: RPCRegisterToken.action(payload!))
                    }
                    
                } else {
                    
                    
                }
                
            } catch RPCErrors.DuplicateRequest {
                
                
                
            } catch RPCErrors.InvalidRequest {
                
                
                
            } catch {
                
                
                
            }
            
        }
        
        response.completed()
    }
}
