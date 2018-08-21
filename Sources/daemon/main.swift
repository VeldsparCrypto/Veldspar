//    MIT License
//
//    Copyright (c) 2018 Veldspar Team
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
import VeldsparCore
import PerfectHTTP
import PerfectHTTPServer

// defaults
var port: Int = 14242

print("---------------------------")
print("\(Config.CurrencyName) Daemon v\(Config.Version)")
print("---------------------------")

var cacheSize = 128*1024
var isGenesis = false
let args: [String] = CommandLine.arguments

if args.count > 1 {
    for arg in args {
        if arg.lowercased() == "--help" {
            print("\(Config.CurrencyName) - v\(Config.Version)")
            print("-----   COMMANDS -------")
            print("--debug          : enables debug output to console")
            exit(0)
        }
        if arg.lowercased() == "--debug" {
            debug_on = true
        }
        if arg.lowercased() == "--genesis" {
            // setup the blockchain with an empty block starting the generation of Ore
            isGenesis = true
        }
        if arg.lowercased() == "--cache64" {
            cacheSize = 64*1024
        }
        if arg.lowercased() == "--cache128" {
            cacheSize = 128*1024
        }
        if arg.lowercased() == "--cache256" {
            cacheSize = 256*1024
        }
        if arg.lowercased() == "--cache512" {
            cacheSize = 512*1024
        }
    }
}

// open the database connection
Database.Initialize()
print("Database connection opened")
var blockchain = BlockChain()

if isGenesis {
    if blockchain.blockAtHeight(0) != nil {
        print("Genesis block has already been created, exiting.")
        exit(0)
    }
    
    let firstBlock = Block(height: 0)
    firstBlock.oreSeed = Config.GenesisID
    firstBlock.transactions = []
    firstBlock.hash = firstBlock.GenerateHashForBlock(previousHash: "")
    if(!Database.WriteBlock(firstBlock)) {
        print("Unable to write initial genesis block into the blockchain.")
        exit(0)
    }
}

print("Blockchain created, currently at height \(blockchain.height())")
print("Generating Ore")

for o in blockchain.oreSeeds() {
    let _ = Ore(o.oreSeed!, height: o.height)
}

print("Generating missing stats")
while blockchain.StatsHeight() < blockchain.height() {
    let height = blockchain.StatsHeight() + 1
    print("generating stats for block \(height)")
    blockchain.GenerateStatsFor(block: height)
}
    
Execute.background {
    
    // endlessly run the main process loop
    BlockMaker.Loop()
    
}

do {
    
    // Launch the servers based on the configuration data.
    var r = Routes()
    try r.add(uri: "/**", handler: handleRequest())
    let server = HTTPServer()
    server.serverPort = UInt16(port)
    server.addRoutes(r)
    try server.start()
    
} catch {
    print("error: unable to start rest service.\n")
}
