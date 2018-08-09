//
//  generic_comms.swift
//  VeldsparCore
//
//  Created by Adrian Herridge on 04/08/2018.
//

import Foundation
import PerfectCURL

public class Comms {
    
    public class func request(method: String, parameters: [String:String]?) -> Data? {
        
        var encodedParams: [String] = []
        for p in parameters ?? [:] {
            let value = "\(p.key)=\(p.value)".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            encodedParams.append(value!)
        }
        
        let result = try? CURLRequest("http://\(Config.SeedNodes[0])/\(method)?\(encodedParams.joined(separator: "&"))",.timeout(30)).perform()
        
        if result == nil {
            return nil
        }
        
        if result!.responseCode != 200 {
            return nil
        }
        
        if result!.bodyBytes.count == 0 {
            return nil
        }
        
        return Data(bytes: result!.bodyBytes)
        
    }
    
    public class func requestJSON(method: String, parameters: [String:String]?) -> [String:Any]? {
        
        var encodedParams: [String] = []
        for p in parameters ?? [:] {
            let value = "\(p.key)=\(p.value)".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            encodedParams.append(value!)
        }
        
        let result = try? CURLRequest("http://\(Config.SeedNodes[0])/\(method)?\(encodedParams.joined(separator: "&"))",.timeout(30)).perform()
        
        if result == nil {
            return nil
        }
        
        if result!.responseCode != 200 {
            return nil
        }
        
        if result!.bodyBytes.count == 0 {
            return nil
        }
        
        return result!.bodyJSON
        
    }
    
    public class func requestHeight() -> UInt32? {
    
        let response = requestJSON(method: "blockchain/currentheight", parameters: nil)
        if response != nil {
            
            if response!["height"] != nil {
                
                for v in response! {
                    if v.key == "height" {
                        return UInt32(v.value as! Int)
                    }
                }
                
            }
            
        }
        
        return nil
    
    }
    
}
