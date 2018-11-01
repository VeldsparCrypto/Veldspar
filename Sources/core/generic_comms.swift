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
    
    public class func get(url: String, parameters: [String:String]?) -> Data?  {
        
        var encodedParams: [String] = []
        for p in parameters ?? [:] {
            let value = "\(p.key)=\(p.value)".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            encodedParams.append(value!)
        }
        
        let client = Client().onError { (err) in
            
        }
        
        // this is an async call, so we want to block and use it as a sync call
        var response: Data?
        let waitSemaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
        
        client.get(url: url).query(query: parameters ?? [:]).end(done: { (res) in
            
            if res.basicStatus == .ok {
                response = res.data
            }
            
            waitSemaphore.signal()
            
        }) { (err) in
            
            waitSemaphore.signal()
            
        }
        
         waitSemaphore.wait()
        
        return response
        
    }
    
    public class func request(method: String, parameters: [String:String]?) -> Data? {
        
        return get(url:"http://\(Config.SeedNodes[0])/\(method)", parameters:parameters)
        
    }
    
    public class func requestJSON(method: String, parameters: [String:String]?) -> [String:Any]? {
        
        var encodedParams: [String] = []
        for p in parameters ?? [:] {
            let value = "\(p.key)=\(p.value)".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            encodedParams.append(value!)
        }
        
        let client = Client().onError { (err) in
            
        }
        
        // this is an async call, so we want to block and use it as a sync call
        var response: [String:Any]?
        let waitSemaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
        
        client.get(url: "http://\(Config.SeedNodes[0])/\(method)").query(query: parameters ?? [:]).end(done: { (res) in
            
            if res.basicStatus == .ok {
                if res.data != nil {
                    do {
                        response = try JSONSerialization.jsonObject(with: res.data!, options: []) as? [String: Any]
                    } catch {
                        
                    }
                }
            }
            
            waitSemaphore.signal()
            
        }) { (err) in
            
            waitSemaphore.signal()
            
        }
        
        waitSemaphore.wait()
        
        return response

    }
    
    public class func blockAtHeight(height: Int) -> Block {
        
        let blockData = Comms.request(method: "blockchain/block", parameters: ["height" : "\(height)"])
        if blockData != nil {
            
            let b = try? JSONDecoder().decode(Block.self, from: blockData!)
            if b != nil {
                return b!
            }
            
        }
        
        return Block()
        
    }
    
    public class func requestHeight() -> Int? {
    
        let response = requestJSON(method: "blockchain/currentheight", parameters: nil)
        if response != nil {
            
            if response!["height"] != nil {
                
                for v in response! {
                    if v.key == "height" {
                        return v.value as? Int
                    }
                }
                
            }
            
        }
        
        return nil
    
    }
    
}
