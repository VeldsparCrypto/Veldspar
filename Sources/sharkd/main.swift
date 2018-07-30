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

import SharkCore
import PerfectHTTP
import PerfectHTTPServer

// defaults
var port: Int = 14242

print("---------------------------")
print("\(Config.CurrencyName) Daemon v\(Config.Version)")
print("---------------------------")

// open the database connection
Database.Initialize()
print("Database connection opened")

let args: [String] = CommandLine.arguments
var debug = false;

if args.count > 1 {
    for arg in args {
        if arg.lowercased() == "--debug" {
            debug = true
        }
        if arg.lowercased() == "--genesis" {
            // setup the blockchain with an empty block starting the generation of Ore
            let firstBlock = Block(height: 0)
            firstBlock.oreSeed = Config.GenesisID
            firstBlock.transactions = []
            firstBlock.hash = firstBlock.GenerateHashForBlock(previousHash: "")
            if(!Database.WriteBlock(firstBlock)) {
                assertionFailure("Unable to write initial genesis block into the blockchain.")
            }
        }
    }
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
