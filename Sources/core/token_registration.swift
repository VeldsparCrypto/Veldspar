//
//  token_registration.swift
//  miner
//
//  Created by Adrian Herridge on 03/08/2018.
//

import Foundation

public class TokenRegistration {
    
    public class func Register(token: String, address: String, nodeAddress: String) -> Int? {
        
        let response = Comms.request(method: "token/register", parameters: ["token":token, "address":address])
        if response != nil {
            // we have a valid response
            let resObject: RPC_Register_Repsonse? = try? JSONDecoder().decode(RPC_Register_Repsonse.self, from: response!)
            if resObject != nil {
                
                // check for failure
                if resObject?.success == false {
                    return -1 // specific, communication was fine, but registration was unsuccessful
                }
                
                // successfully written, return the height at which it was placed
                return resObject?.block
                
            }
            
        }
        
        return nil
        
    }
    
}
