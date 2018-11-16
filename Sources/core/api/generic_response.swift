//
//  generic_response.swift
//  VeldsparCore
//
//  Created by Adrian Herridge on 15/11/2018.
//

import Foundation

public class GenericResponse : Codable {
    
    public var success: Bool
    public var error: String?
    public var info: [String:String] = [:]
    
    public init(error: String) {
        success = false
        self.error = error
    }
    
    public init(values: [(key: String, value: String)]) {
        success = true
        for kvp in values {
            info[kvp.key] = kvp.value
        }
    }
    
    public init(key: String, value: String) {
        success = true
        info = [key:value]
    }
    
    public init() {
        success = true
    }
    
}
