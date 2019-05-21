//
//  transfer_request.swift
//  VeldsparCore
//
//  Created by Adrian Herridge on 21/05/2019.
//

import Foundation

public class CreateTransferRequest : Codable {
    
    public var address: Data?
    public var target: Data?
    public var amount: Int?
    public var reference: Data?
    
    public init() {}
    
}
