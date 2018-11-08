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
    
    public class func request(method: String, parameters: [String:String]?) -> Data? {
        
        var encodedParams: [String] = []
        for p in parameters ?? [:] {
            let value = "\(p.key)=\(p.value)".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            encodedParams.append(value!)
        }
        
        return try? String(contentsOf: URL(string:"http://\(Config.SeedNodes[0])/\(method)?\(encodedParams.joined(separator: "&"))")! , encoding: .ascii).data(using: .ascii)!
        
    }
    
    public class func blockAtHeight(height: Int) -> Block? {
        
        let blockData = Comms.request(method: "blockchain/block", parameters: ["height" : "\(height)"])
        if blockData != nil {
            
            let b = try? JSONDecoder().decode(Block.self, from: blockData!)
            if b != nil {
                return b!
            }
            
        }
        
        return nil
        
    }
    
    public class func hashForBlock(height: Int) -> Data? {
        
        let blockData = Comms.request(method: "blockchain/blockhash", parameters: ["height" : "\(height)"])
        if blockData != nil {
            
            let b = try? JSONDecoder().decode(BlockHashObject.self, from: blockData!)
            if b != nil {
                return b?.hash
            }
            
        }
        
        return nil
        
    }
    
    public class func requestHeight() -> Int? {
        
        let method = "blockchain/currentheight"
        let responseData = try? String(contentsOf: URL(string:"http://\(Config.SeedNodes[0])/\(method)")! , encoding: .ascii).data(using: .ascii)!
        
        if responseData != nil {
            
            let response = try? JSONDecoder().decode(CurrentHeightObject.self, from: responseData!)
            if response != nil {
                
                return response?.height!
                
            }
            
        }
        
        return nil
    
    }
    
}
