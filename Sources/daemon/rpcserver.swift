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
                
                let r = "\(Config.CurrencyName) Daemon \(Config.Version)"
                logger.log(level: .Debug, log: "(RPC) '\(request.path)'")
                return .ok(.html(r))
                
            case "/timestamp":
                
                if !settings.rpc_allow_timestamp {
                    return .forbidden
                }
                
                return .ok(.jsonString("{\"timestamp\" : \(consensusTime())}"))
                
            case "/currentheight":
                
                if !settings.rpc_allow_height {
                    return .forbidden
                }
                
                let filePath = "./cache/blocks/current.height"
                
                // check to see if there is a local cache file, if not generate a block
                let r = try? Data(contentsOf: URL(fileURLWithPath: filePath))
                if r != nil {
                    
                    return .ok(.jsonData(r!))
                    
                } else {
                    
                    let r = "{\"height\" : \(blockchain.height())}"
                    logger.log(level: .Debug, log: "(RPC) '\(request.path)'")
                    return .ok(.jsonString(r))
                    
                }
                
            case "/block":
                
                if !settings.rpc_allow_block {
                    return .forbidden
                }
                
                var height = 0
                for p in request.queryParams {
                    if p.0 == "height" {
                        height = Int(p.1) ?? 0
                    }
                }
                
                let filePath = "./cache/blocks/\(height).block"
                
                // check to see if there is a local cache file, if not generate a block
                let r = try? Data(contentsOf: URL(fileURLWithPath: filePath))
                if r != nil {
                    
                    return .ok(.jsonData(r!))
                    
                } else {
                    
                    let block = blockchain.blockAtHeight(height, includeTransactions: true)
                    if block != nil {
                        
                        let d = try? JSONEncoder().encode(block!)
                        if d != nil {
                            
                            return .ok(.jsonData(d!))
                            
                        } else {
                            
                            return .notFound
                            
                        }
                        
                    } else {
                        return .notFound
                    }
                    
                }
                
            case "/register":
                
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
                
                logger.log(level: .Debug, log: "(RPC) '\(request.path)' token='\(token)' address='\(address)'")
                
                // flush this out to disk asap
                let s = "{\"token\" : \"\(token)\", \"address\" : \"\(address)\"}"
                tempManager.putRegister(s.data(using: .ascii)!, src: request.address)
                
                return .ok(.jsonData(try JSONEncoder().encode(GenericResponse(key: "received", value: "ok"))))
                
            case "/int":
                
                if request.method != "POST" {
                    throw RPCErrors.InvalidRequest
                }
                
                if request.body.count < 2 {
                    throw RPCErrors.InvalidRequest
                }
                
                // flush to disk and return
                tempManager.putInterNodeTransfer(Data(bytes: request.body), src: request.address)
                
                return .ok(.jsonData(try JSONEncoder().encode(GenericResponse(key: "received", value: "ok"))))
                
            case "/announce":
                
                var nodeId = ""
                var port = ""
                for p in request.queryParams {
                    if p.0.lowercased() == "nodeid" {
                        nodeId = p.1
                    }
                    if p.0.lowercased() == "port" {
                        port = p.1
                    }
                }
                
                logger.log(level: .Debug, log: "(RPC) '\(request.path)' nodeId='\(nodeId)'")
                
                Execute.background {
                    
                    let node = PeeringNode()
                    node.address = "\(request.address!):\(port)"
                    node.uuid = nodeId
                    node.lastcomm = UInt64(Date().timeIntervalSince1970 * 1000)
                    if comms.basicRequest(address: node.address ?? "", method: "/timestamp", parameters: [:]) != nil {
                        node.reachable = 1
                        logger.log(level: .Info, log: "Registering node (\(nodeId) on port \(port) from IP \(request.address ?? "UNKNOWN")")
                    } else {
                        node.reachable = 0
                        logger.log(level: .Info, log: "Registering node (\(nodeId) on port \(port) from IP \(request.address ?? "UNKNOWN") failed, not reachable.")
                    }
                    blockchain.putNode(node)
                    
                }
                
                return .ok(.jsonData(try JSONEncoder().encode(GenericResponse(key: "node", value: "registered"))))
                
            case "/nodes":
                
                logger.log(level: .Debug, log: "(RPC) '\(request.path)'")
                
                let nodes = blockchain.nodesAll()
                let nodeResponse = NodeListResponse()
                nodeResponse.nodes = nodes
                return .ok(.jsonData(try JSONEncoder().encode(nodeResponse)))
                
            case "/blockhash":
                
                logger.log(level: .Debug, log: "(RPC) '\(request.path)'")
                
                var height = -1
                for p in request.queryParams {
                    if p.0 == "height" {
                        height = Int(p.1) ?? 0
                    }
                }
                
                var blockHash = BlockHash()
                let block = blockchain.blockAtHeight(height, includeTransactions: false)
                if block != nil && block?.hash != nil {
                    
                    blockHash.ready = true
                    blockHash.height = height
                    blockHash.hash = block?.hash
                    blockHash.nodeId = thisNode.nodeId
                    
                } else {
                    
                    blockHash.ready = false
                    
                }
                
                return .ok(.jsonData(try JSONEncoder().encode(blockHash)))
                
            case "/transfer":
                
                // just flush to disk and return generic response
                tempManager.putTransfer(Data(bytes: request.body), src: request.address)
                
                return .ok(.jsonData(try JSONEncoder().encode(GenericResponse(key: "received", value: "ok"))))
                
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

