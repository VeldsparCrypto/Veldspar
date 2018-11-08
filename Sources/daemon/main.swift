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
import Swifter

// defaults
var port: Int = 14242

print("---------------------------")
print("\(Config.CurrencyName) Daemon v\(Config.Version)")
print("---------------------------")

var isGenesis = false
var isTestNet = false
var isLocal = false
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
        if arg.lowercased() == "--testnet" {
            isTestNet = true
        }
        if arg.lowercased() == "--local" {
            isLocal = true
        }
    }
}

let ore = Ore(Config.GenesisID, height: 0)
let v3Beans = AlgorithmSHA512AppendV0.beans()
var settings = Settings()
if FileManager.default.fileExists(atPath: "veldspar.settings") {
    let settingsData: Data? = try? Data(contentsOf: URL(fileURLWithPath: "veldspar.settings"))
    if settingsData != nil {
        let newSettings = try? JSONDecoder().decode(Settings.self, from: settingsData!)
        if newSettings != nil {
            settings = newSettings!
        }
    }
}

// write out the settings file again, which will add any new keys and their default values
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted]
try? encoder.encode(settings).write(to: URL(fileURLWithPath: "veldspar.settings"))


// open the database connection
Database.Initialize()

let logger = Logger()
print("Database(s) opened")
var blockchain = BlockChain()

if isGenesis {
    if blockchain.blockAtHeight(0, includeTransactions: false) != nil {
        print("Genesis block has already been created, exiting.")
        exit(0)
    }
    
    var firstBlock = Block()
    firstBlock.height = 0
    firstBlock.transactions = []
    firstBlock.hash = firstBlock.GenerateHashForBlock(previousHash: Data())
    if(!Database.WriteBlock(firstBlock)) {
        print("Unable to write initial genesis block into the blockchain.")
        exit(0)
    }
    print("genesis block created, please restart daemon without `--genesis` flag.")
    exit(0)
} 

if isTestNet {
    print("")
    print("********************************************")
    print("** WARNING: RUNNING IN TESTNET MODE       **")
    print("********************************************")
    print("")
}

print("Blockchain created, currently at height \(blockchain.height())")

Execute.background {
    // endlessly run the main process loop
    if settings.blockchain_produce_blocks {
        logger.log(level: .Info, log: "Block maker started")
        BlockMaker.Loop()
    } else {
        // retrieve blocks from the cache service and wite them into the local blockchain
        logger.log(level: .Info, log: "Node not configured to make blocks, so synchronising blocks with network instead")
    }
}

// now start the webserver and block
RPCServer.start()

let waiter = DispatchSemaphore(value: 0)
waiter.wait()
