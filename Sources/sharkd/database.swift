//    MIT License
//
//    Copyright (c) 2018 SharkChain Team
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.

import Foundation
import SWSQLite
import SharkCore

let blockchain_db = SWSQLite(path: "\(URL(fileURLWithPath: NSHomeDirectory())).\(Config.CurrencyName)", filename: "blockchain.db")

class Database {
    
    class func Initialize() {
        
        _ = blockchain_db.execute(sql: "CREATE TABLE IF NOT EXISTS block (height INTEGER PRIMARY KEY, hash TEXT, oreSeed TEXT)", params: [])
        _ = blockchain_db.execute(sql: "CREATE TABLE IF NOT EXISTS block_transaction (id TEXT PRIMARY KEY,height INTEGER, type INTEGER, key TEXT, signature TEXT, dest TEXT, ref TEXT, value INTEGER, date INTEGER, tokens TEXT)", params: [])
        _ = blockchain_db.execute(sql: "CREATE TABLE IF NOT EXISTS ledger (id INTEGER PRIMARY KEY AUTOINCREMENT,op INTEGER, date INTEGER, transaction TEXT, owner TEXT, token TEXT, checksum TEXT)", params: [])
        
    }
    
    class func WriteBlock(_ block: Block) -> Bool {
        
        return false
    }
    
    class func BlockAtHeight(_ height: UInt64) -> Block? {
        
        return nil
    }
    
}
