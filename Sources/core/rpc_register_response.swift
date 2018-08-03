//
//  rpc_register_response.swift
//  VeldsparCore
//
//  Created by Adrian Herridge on 03/08/2018.
//

import Foundation

public class RPC_Register_Repsonse : Codable {
    
    public var success: Bool?
    public var token: String?
    public var block: Int?
    
    public init() {}
    
}
