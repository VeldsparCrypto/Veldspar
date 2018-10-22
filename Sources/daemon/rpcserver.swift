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
import Swifter

public let registrationsLock = Mutex()
public var registrations: [Registration] = []
let banLock: Mutex = Mutex()
var bans: [String:Int] = [:]


enum RPCErrors : Error {
    case InvalidRequest
    case DuplicateRequest
    case Banned
}

class RPCHandler {
    
    func request(_ request: HttpRequest) -> HttpResponse {
        
        do {
            
            let start = Date().timeIntervalSince1970
            
            var queryParamsDictionary: [String:String] = [:]
            for o in request.queryParams {
                queryParamsDictionary[o.0] = o.1
            }
            
            var qs = ""
            for k in queryParamsDictionary.keys.sorted() {
                qs += "\(k)=\(queryParamsDictionary[k]!)"
            }
            
            
            switch request.path {
            case "/":
                
                let r = RPCStatsPage.createPage(blockchain.getStats())
                
                logger.log(level: .Warning, log: "(RPC) '\(request.path)'", token: nil, source: request.address!, duration: Int((Date().timeIntervalSince1970 - start) * 1000))
                
                return .ok(.html(r))
                
            case "/info/timestamp":
                
                return .ok(.jsonString("{\"timestamp\" : \(consensusTime())}"))
                
            case "/blockchain/seeds":
                
                var encodedData = try String(bytes: JSONEncoder().encode(RPCOreSeeds.action()), encoding: .ascii)
                if encodedData == nil {
                    encodedData = ""
                }
                
                return .ok(.jsonString(encodedData!))
                
            case "/blockchain/currentheight":
                
                let r = "{\"height\" : \(blockchain.height())}"
                log(level: .Warning, log: "(RPC) '\(request.path)'", token: nil, source: request.address!, duration: Int((Date().timeIntervalSince1970 - start) * 1000))
                
                return .ok(.jsonString(r))
                
            case "/blockchain/stats":
                
                let r = RPCStats.action()
                
                logger.log(level: .Warning, log: "(RPC) '\(request.path)'", token: nil, source: request.address!, duration: Int((Date().timeIntervalSince1970 - start) * 1000))
                
                return .ok(.jsonString(r))
                
            case "/blockchain/block":
                
                var height = 0
                for p in request.queryParams {
                    if p.0 == "height" {
                        height = Int(p.1) ?? 0
                    }
                }
                
                let filePath = "\(NSHomeDirectory())/.\(Config.CurrencyName)/cache/\(height).block"
                
                // check to see if there is a local cache file
                if FileManager.default.fileExists(atPath: filePath) {
                    
                    let r = try? String(contentsOf: URL(fileURLWithPath: filePath), encoding: .ascii)
                    return .ok(.jsonString(r ?? ""))
                    
                } else {
                    
                    return .notFound
                    
                }
                
            case "/token/register":
                
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
                
                logger.log(level: .Warning, log: "(RPC) '\(request.path)' token='\(token)' address='\(address)'", token: token, source: request.address!, duration: Int((Date().timeIntervalSince1970 - start) * 1000))
                
                // try response.setBody(json: )
                let r = try? RPCRegisterToken.action(["token" : token, "address" : address], host: request.address)
                return .ok(.json(r!))
                
            default:
                return .notFound
            }
            
        } catch RPCErrors.Banned {
            
            return .forbidden
            
        } catch RPCErrors.DuplicateRequest {
            
            return .badRequest(.html("Veldspar: Duplicate Request"))
            
        } catch RPCErrors.InvalidRequest {
            
            return .badRequest(.html("Veldspar: Bad Request"))
            
        } catch {
            
            return .internalServerError
            
        }
        
    }
    
}

class RPCServer {
    
    static var this = RPCServer()
    var server: HttpServer = HttpServer()
    
    class func start() {
        
        this.server[""] = { request in
            return RPCHandler().request(request)
        }
        this.server["*"] = { request in
            return RPCHandler().request(request)
        }
        this.server["*/*"] = { request in
            return RPCHandler().request(request)
        }
        this.server["*/*/*"] = { request in
            return RPCHandler().request(request)
        }
        
        try? this.server.start(14242, forceIPv4: true, priority: .default)
        
    }
    
}

