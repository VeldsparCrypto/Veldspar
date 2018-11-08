//
//  peering_node.swift
//  VeldsparCore
//
//  Created by Adrian Herridge on 06/11/2018.
//

import Foundation

public struct PeeringNode : Codable {
    
    public var id: Int?
    public var uuid: String?
    public var address: String?
    public var speed: Int?
    public var failures: Int?
    public var timemark: Int?
    
    public init() {}
    
}
