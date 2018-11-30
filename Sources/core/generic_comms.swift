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
import SwiftClient
import Dispatch

public class Comms {
    
    var node: String
    
    public init(endpoint: String) {
        node = endpoint
    }
    
    public func basicRequest(address: String, method: String, parameters: [String:String]? ) -> Data? {
        
        var encodedParams: [String] = []
        for p in parameters ?? [:] {
            let value = "\(p.key)=\(p.value)".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            encodedParams.append(value!)
        }
        
        return try? Data(contentsOf: URL(string:"http://\(address)/\(method)?\(encodedParams.joined(separator: "&"))")!)
        
    }
    
    public func request(method: String, parameters: [String:String]?) -> Data? {
        
        var encodedParams: [String] = []
        for p in parameters ?? [:] {
            let value = "\(p.key)=\(p.value)".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            encodedParams.append(value!)
        }
        
        return try? String(contentsOf: URL(string:"http://\(node)/\(method)?\(encodedParams.joined(separator: "&"))")! , encoding: .ascii).data(using: .ascii)!
        
    }
    
    public func blockAtHeight(height: Int) -> Block? {
        
        let blockData = request(method: "block", parameters: ["height" : "\(height)"])
        if blockData != nil {
            
            let b = try? JSONDecoder().decode(Block.self, from: blockData!)
            if b != nil {
                return b!
            }
            
        }
        
        return nil
        
    }
    
    public func blockDataAtHeight(height: Int) -> Data? {
        
        let blockData = request(method: "block", parameters: ["height" : "\(height)"])
        if blockData != nil {
            
            return blockData
            
        }
        
        return nil
        
    }
    
    public func hashForBlock(address: String, height: Int) -> BlockHash? {
        
        let blockData = basicRequest(address: address, method: "blockhash", parameters: ["height" : "\(height)"])
        if blockData != nil {
            
            let b = try? JSONDecoder().decode(BlockHash.self, from: blockData!)
            if b != nil {
                return b!
            }
            
        }
        
        return nil
        
    }
    
    public func hashForBlock(height: Int) -> BlockHash? {
        
        var node = "127.0.0.1:14242"
        return hashForBlock(address: node, height: height)
        
    }
    
    public func announce(nodeId: String, port: Int) -> Bool {
        
        let blockData = request(method: "announce", parameters: ["nodeId" : nodeId, "port" : "\(port)"])
        if blockData != nil {
            return true
        }
        return false
        
    }
    
    public func nodes() -> NodeListResponse {
        
        let blockData = request(method: "nodes", parameters: [:])
        if blockData != nil {
            
            let b = try? JSONDecoder().decode(NodeListResponse.self, from: blockData!)
            if b != nil {
                return b!
            }
            
        }
        
        return NodeListResponse()
        
    }
    
    public func pending(height: Int, tidemark: Int) -> Ledgers {
        
        let blockData = request(method: "pending", parameters: ["height":"\(height)", "tidemark" : "\(tidemark)"])
        if blockData != nil {
            
            let b = try? JSONDecoder().decode(Ledgers.self, from: blockData!)
            if b != nil {
                return b!
            }
            
        }
        
        return Ledgers()
        
    }
    
    public func Register(token: String, address: String) -> RegisterRepsonse? {
        
        let response = request(method: "register", parameters: ["token" : token, "address" : address])
        if response != nil  {
            let r = try? JSONDecoder().decode(RegisterRepsonse.self, from: response!)
            if r != nil {
                return r
            }
        }
        
        return nil
        
    }
    
    public func requestHeight() -> Int? {
        
        let method = "currentheight"
        let responseData = try? String(contentsOf: URL(string:"http://\(node)/\(method)")! , encoding: .ascii).data(using: .ascii)!
        
        if responseData != nil {
            
            let response = try? JSONDecoder().decode(CurrentHeightObject.self, from: responseData!)
            if response != nil {
                
                return response?.height!
                
            }
            
        }
        
        return nil
    
    }
    
}
