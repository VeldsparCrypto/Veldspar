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

public let registrationsLock = Mutex()
public var registrations: [Registration] = []
let cacheLock: Mutex = Mutex()
var cache: [String:String] = [:]
let banLock: Mutex = Mutex()
var bans: [String:Int] = [:]


enum RPCErrors : Error {
    case InvalidRequest
    case DuplicateRequest
    case Banned
}

public func clearCache() {
    cacheLock.mutex {
        cache.removeAll()
    }
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
        
        let start = Date().timeIntervalSince1970
        
        if request.method == .get {
            
            do {
                
                var queryParamsDictionary: [String:String] = [:]
                for o in request.queryParams {
                    queryParamsDictionary[o.0] = o.1
                }
                
                var qs = ""
                for k in queryParamsDictionary.keys.sorted() {
                    qs += "\(k)=\(queryParamsDictionary[k]!)"
                }
                
                let cacheIndex = request.path + qs
                
                var cachedResult: String?
                cacheLock.mutex {
                    cachedResult = cache[cacheIndex]
                }
                
                if cachedResult == nil {
                    
                    if request.path == "/" {
                        
                        response.setHeader(.contentType, value: "text/html")
                        let r = RPCStatsPage.createPage(blockchain.getStats())
                        cacheLock.mutex {
                            cache[cacheIndex] = r
                        }
                        response.setBody(string: r)
                        
                        logger.log(level: .Warning, log: "(RPC) '\(request.path)'", token: nil, source: request.remoteAddress.host, duration: Int((Date().timeIntervalSince1970 - start) * 1000))
                        
                    }
                    
                    if request.path == "/info/timestamp" {
                        try response.setBody(json: ["timestamp" : consensusTime()])
                    }
                    
                    if request.path == "/blockchain/currentheight" {
                        
                        let r = try? ["height" : blockchain.height()].jsonEncodedString()
                        cacheLock.mutex {
                            cache[cacheIndex] = r ?? ""
                        }
                        response.setBody(string: r ?? "" )
                        
                        logger.log(level: .Warning, log: "(RPC) '\(request.path)'", token: nil, source: request.remoteAddress.host, duration: Int((Date().timeIntervalSince1970 - start) * 1000))
                        
                    }
                    
                    if request.path == "/blockchain/seeds" {
                        
                        let encodedData = try String(bytes: JSONEncoder().encode(RPCOreSeeds.action()), encoding: .ascii)
                        
                        if encodedData != nil {
                            cacheLock.mutex {
                                cache[cacheIndex] = encodedData!
                            }
                            
                            response.setBody(string: encodedData!)
                        }
                        
                        logger.log(level: .Warning, log: "(RPC) '\(request.path)'", token: nil, source: request.remoteAddress.host, duration: Int((Date().timeIntervalSince1970 - start) * 1000))
                        
                    }
                    
                    if request.path == "/blockchain/stats" {
                        
                        let r = RPCStats.action()
                        cacheLock.mutex {
                            cache[cacheIndex] = r
                        }
                        response.setBody(string: r )
                        
                        logger.log(level: .Warning, log: "(RPC) '\(request.path)'", token: nil, source: request.remoteAddress.host, duration: Int((Date().timeIntervalSince1970 - start) * 1000))

                    }
                    
                    if request.path == "/blockchain/block" {
                        
                        // query the ledger at a specific height, and return the transactions.  Used for wallet implementations
                        var height = 0
                        for p in request.queryParams {
                            if p.0 == "height" {
                                height = Int(p.1) ?? 0
                            }
                        }
                        
                        let encodedData = try String(bytes: JSONEncoder().encode(RPCGetBlock.action(height)), encoding: .ascii)
                        cacheLock.mutex {
                            cache[request.path] = encodedData
                        }
                        response.setBody(string: encodedData!)
                        
                        logger.log(level: .Warning, log: "(RPC) '\(request.path)' block=\(height)", token: nil, source: request.remoteAddress.host, duration: Int((Date().timeIntervalSince1970 - start) * 1000))
                        
                    }
                    
                    if request.path == "/wallet/sync" {
                        
                        // query the ledger at a specific height, and return the transactions.  Used for wallet implementations
                        var height = 0
                        var address = ""
                        for p in request.queryParams {
                            if p.0 == "height" {
                                height = Int(p.1) ?? 0
                            }
                            if p.0 == "address" {
                                address = p.1
                            }
                        }
                        
                        let encodedData = try String(bytes: JSONEncoder().encode(RPCSyncWallet.action(address: address, height: height)), encoding: .ascii)
                        if encodedData != nil {
                            cacheLock.mutex {
                                cache[cacheIndex] = encodedData!
                            }
                        }
                        response.setBody(string: encodedData!)
                        
                        logger.log(level: .Warning, log: "(RPC) '\(request.path)' address='\(address)' height=\(height)", token: nil, source: request.remoteAddress.host, duration: Int((Date().timeIntervalSince1970 - start) * 1000))
                        
                    }
                    
                    if request.path == "/token/register" {
                        
                        let host = request.remoteAddress.host
                        var banned = false
                        banLock.mutex {
                            if bans[host] != nil {
                                if bans[host]! == 10 {
                                    logger.log(level: .Warning, log: "(BAN) Banned address '\(host)'", token: nil, source: host, duration: 0)
                                    banned = true
                                }
                            }
                        }
                        if banned {
                            throw RPCErrors.Banned
                        }
                        
                        var token = ""
                        var address = ""
                        for p in request.queryParams {
                            if p.0 == "token" {
                                token = p.1
                            }
                            if p.0 == "address" {
                                address = p.1
                            }
                        }
                        
                        registrationsLock.mutex {
                            registrations.append(Registration(tokenId: token, src: request.remoteAddress.host, dest: address, height: Int(blockchain.height()) + Config.TransactionMaturityLevel))
                        }
                        
                        try response.setBody(json: ["success" : true, "token" : token, "block" : 0])
                        logger.log(level: .Warning, log: "(RPC) '\(request.path)' token='\(token)' address='\(address)'", token: token, source: request.remoteAddress.host, duration: Int((Date().timeIntervalSince1970 - start) * 1000))
                        
                    }
                    
                } else {
                    
                    if request.path == "/" {
                        response.setHeader(.contentType, value: "text/html")
                    }
                    
                    // we have a cache hit, so return that.
                    response.setBody(string: cachedResult!)
                    
                }
                
                
                
            } catch RPCErrors.Banned {
                
                response.status = .forbidden
                
            } catch {
                
                logger.log(level: .Warning, log: "(RPC) '\(request.path)' (handleRequest) call to RPCServer caused an exception.", token: nil, source: request.remoteAddress.host, duration: Int((Date().timeIntervalSince1970 - start) * 1000))
                
            }
            
            
        } else if request.method == .post {
            
            do {
                
                if payload != nil {
                    
                    if request.path == "/token/register" {
                        try response.setBody(json: RPCRegisterToken.action(payload!, host: request.remoteAddress.host))
                    }
                    
                    if request.path == "/token/transfer" {
                        try response.setBody(json: RPCTransferToken.action(payload!))
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
