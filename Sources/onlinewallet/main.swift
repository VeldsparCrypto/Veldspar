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
var port: Int = 8081

var isTestNet = false
var isLocal = false
let args: [String] = CommandLine.arguments

if args.count > 1 {
    for arg in args {
        if arg.lowercased() == "--help" {
            print("---------------------------")
            print("\(Config.CurrencyName) Online Wallets v\(Config.Version)")
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

// open the database connection
Database.Initialize()

let logger = Logger(debug: debug_on)

logger.log(level: .Info, log: "---------------------------")
logger.log(level: .Info, log: "\(Config.CurrencyName) Online Wallets v\(Config.Version)")
logger.log(level: .Info, log: "---------------------------")

logger.log(level: .Info, log: "Database(s) opened")
var blockchain = BlockChain()

if isTestNet {
    logger.log(level: .Info, log: "")
    logger.log(level: .Info, log: "********************************************")
    logger.log(level: .Info, log: "** WARNING: RUNNING IN TESTNET MODE       **")
    logger.log(level: .Info, log: "********************************************")
    logger.log(level: .Info, log: "")
}

logger.log(level: .Info, log: "Blockchain exists, currently at height \(blockchain.height())")

let thisNode = UUID().uuidString.lowercased()

let blockmaker = BlockMaker()

// now start the webserver and block
RPCServer.start()

let waiter = DispatchSemaphore(value: 0)
waiter.wait()
