//
//  SeedListResponse.swift
//  VeldsparCore
//
//  Created by Adrian Herridge on 02/08/2018.
//

import Foundation

public class RPC_Seed : Codable {
    public var height: Int = 0
    public var seed: String = ""
    public init() {}
}

public class RPC_SeedList : Codable {
    public var seeds: [RPC_Seed] = []
    public init() {}
}
