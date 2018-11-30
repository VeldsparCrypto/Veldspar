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

var isGenesis = false
var isTestNet = false
var isLocal = false
let args: [String] = CommandLine.arguments

let tempManager = TempManager()

if args.count > 1 {
    for arg in args {
        if arg.lowercased() == "--help" {
            print("---------------------------")
            print("\(Config.CurrencyName) Daemon v\(Config.Version)")
            print("---------------------------")
            print("")
            print("\(Config.CurrencyName) - v\(Config.Version)")
            print("-----   COMMANDS -------")
            print("--debug          : enables debug output to console")
            print("--testnet        : connects this node to the testnet")
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
    }
}

var endpointAddress: String?
if isTestNet {
    endpointAddress = Config.TestNetNodes[0]
} else {
    endpointAddress = Config.SeedNodes[0]
}
var comms = Comms(endpoint: endpointAddress!)

let ore = Ore(Config.GenesisID, height: 0)

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

let logger = Logger(debug: debug_on)
let blockmaker = BlockMaker()

logger.log(level: .Info, log: "---------------------------")
logger.log(level: .Info, log: "\(Config.CurrencyName) Daemon v\(Config.Version)")
logger.log(level: .Info, log: "---------------------------")

logger.log(level: .Info, log: "Database(s) opened")
var blockchain = BlockChain()

if isGenesis {
    if blockchain.blockAtHeight(0, includeTransactions: false) != nil {
        logger.log(level: .Info, log: "Genesis block has already been created, exiting.")
        exit(0)
    }
    
    var firstBlock = Block()
    firstBlock.height = 0
    firstBlock.transactions = []
    var newHash = Data()
    newHash.append(Data())
    newHash.append(contentsOf: firstBlock.height!.toHex().bytes)
    newHash.append(blockchain.HashForBlock(firstBlock.height!))
    firstBlock.hash = newHash.sha224()
    if(!Database.WriteBlock(firstBlock)) {
        logger.log(level: .Info, log: "Unable to write initial genesis block into the blockchain.")
        exit(0)
    }
    logger.log(level: .Info, log: "genesis block created, please restart daemon without `--genesis` flag.")
    exit(0)
} 

if isTestNet {
    logger.log(level: .Info, log: "")
    logger.log(level: .Info, log: "********************************************")
    logger.log(level: .Info, log: "** WARNING: RUNNING IN TESTNET MODE       **")
    logger.log(level: .Info, log: "********************************************")
    logger.log(level: .Info, log: "")
}

logger.log(level: .Info, log: "Blockchain exists, currently at height \(blockchain.height())")

// check to see if we have generated a node identifier yet
if db.query(NodeInstance(), sql: "SELECT * FROM NodeInstance", params: []).count == 0 {
    var n = NodeInstance()
    n.nodeId = UUID().uuidString.lowercased()
    _ = db.put(n)
}

let thisNode = db.query(NodeInstance(), sql: "SELECT * FROM NodeInstance", params: [])[0]
let broadcaster = Broadcaster()
let interNodeTransfer = InterNodeTransferProcessor()
let registrations = RegistrationProcessor()
let transfers = TransferProcessor()


// initialisation complete, now we need to work out if we are behind and then play catchup with the network
if !settings.isSeedNode && (blockmaker.currentNetworkBlockHeight() - blockchain.height()) > 1 {
    
    // we are more than the current block +1 out, so we need to play catch-up before starting the webserver and services.
    
    logger.log(level: .Warning, log: "This node is behind the network, playing catchup until up-to-date.")
    
    while blockchain.height() < blockmaker.currentNetworkBlockHeight() {
        
        let b = comms.blockAtHeight(height: blockchain.height()+1)
        if b != nil {
            
            // we have a block, commit it into the datastore
            _ = blockchain.addBlock(b!)
            logger.log(level: .Info, log: "Downloaded block \(b!.height!) with hash \(b!.hash!.toHexString()) from network.")
            
        } else {
            
            logger.log(level: .Warning, log: "Unable to sync with the network, waiting 30s until network is available.")
            Thread.sleep(forTimeInterval: 30.0)
            
        }
        
    }
    
} else if settings.isSeedNode {
    
    // we need to catch up as quickly as possible with any of the transactions we may have missed from the registered nodes.  This happens by suspending block production until reasonable catchups have been achieved.
    
    
}

Execute.background {
    if !settings.isSeedNode {
        logger.log(level: .Info, log: "Node announcer service started")
        let announcer = Announcer()
        announcer.Announce()
    }
}

Execute.background {
    // endlessly run the main process loop
    logger.log(level: .Info, log: "Block formation service started")
    blockmaker.Loop()
}

Execute.background {
    // endlessly sync node peer records
    if !settings.isSeedNode {
        logger.log(level: .Info, log: "Node swarm service started")
        NodeSync.SyncNodes()
    }
}

Execute.background {
    // broadcast transaction data to all visible nodes
    logger.log(level: .Info, log: "Transaction broadcaster service started")
    broadcaster.broadcast()
}

// now start the webserver and block
RPCServer.start()

let waiter = DispatchSemaphore(value: 0)
waiter.wait()
