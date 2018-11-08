//
//  BlockHashObject.swift
//  veldspard
//
//  Created by Adrian Herridge on 08/11/2018.
//

import Foundation

public struct BlockHashObject : Codable {
    
    public var height: Int?
    public var hash: Data?
    public init () {}
    
}
