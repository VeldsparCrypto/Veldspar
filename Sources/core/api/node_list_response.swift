//
//  node_list_response.swift
//  VeldsparCore
//
//  Created by Adrian Herridge on 15/11/2018.
//

import Foundation

public class NodeListResponse : Codable {
    
    public var nodes: [PeeringNode] = []
    public init() {}
    
}
