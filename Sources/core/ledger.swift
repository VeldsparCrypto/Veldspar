//
//  ledger.swift
//  SharkCore
//
//  Created by Adrian Herridge on 30/07/2018.
//

import Foundation

public class Ledger {
    // "CREATE TABLE IF NOT EXISTS ledger (id INTEGER PRIMARY KEY AUTOINCREMENT,op INTEGER, date INTEGER, transaction TEXT, owner TEXT, token TEXT, block INTEGER, checksum TEXT)"
    
    public var id: UInt64?
    public var op: Int?
    public var date: UInt64?
    public var transaction: String?
    public var owner: String?
    public var token: String?
    public var block: UInt64?
    public var checksum: String?
    
}
