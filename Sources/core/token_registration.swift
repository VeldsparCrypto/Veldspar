//
//  token_registration.swift
//  miner
//
//  Created by Adrian Herridge on 03/08/2018.
//

import Foundation
import PerfectCURL

public class TokenRegistration {
    
    public class func Register(token: String, address: String, nodeAddress: String) -> Int? {
        
        let registration = try? CURLRequest("http://\(nodeAddress):14242/token/register?token=\(token)&address=\(address)",.timeout(30)).perform()
        if registration != nil && registration!.bodyBytes.count > 0 {
            let resObject: RPC_Register_Repsonse? = try? JSONDecoder().decode(RPC_Register_Repsonse.self, from: Data(bytes: registration!.bodyBytes))
            if resObject != nil {
                
                // check for failure
                if resObject?.success == false {
                    return -1 // specific, communication was fine, but registration was unsuccessful
                }
                
                // successfully written, return the height at which it was placed
                return resObject?.block
                
            } else {
                // no comms, cache result
                return nil
            }
        } else {
            // no comms, cache result
            return nil
        }
        
    }
    
}
