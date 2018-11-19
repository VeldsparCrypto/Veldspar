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
import Ed25519

#if os(Linux)
srandom(UInt32(time(nil)))
#endif

// defaults
var nodeAddress: String = "127.0.0.1:14242"
var oreBlocks: [Int:Ore] = [:]
var miningMethods: [AlgorithmType] = [AlgorithmType.SHA512_AppendV0]
var walletAddress: String?
var cacheLock = Mutex()
var threads = 4
var isTestnet = false
let args: [String] = CommandLine.arguments
let statsLock: Mutex = Mutex()
var hashes: Int = 0
var matches: Int = 0

if args.count > 1 {
    for i in 1...args.count-1 {
        
        let arg = args[i]
        
        if arg.lowercased() == "--help" {
            print("\(Config.CurrencyName) - Miner - v\(Config.Version)")
            print("-----   COMMANDS -------")
            print("--address          : specifies address to register found tokens, usage: --address VEAWzmytDMpqpDFJqwom9Wqmyp7UReZrC8B")
            print("--threads          : number of threads to mine on")
            print("--dontburncpu      : adds a small sleep to stop CPU from working too hard")
            exit(0)
        }
        if arg.lowercased() == "--debug" {
            debug_on = true
        }
        if arg.lowercased() == "--testnet" {
            isTestnet = true
        }
        if arg.lowercased() == "--address" {
            
            if i+1 < args.count {
                
                let add = args[i+1]
                walletAddress = add
                
            }
            
        }
        if arg.lowercased() == "--node" {
            
            if i+1 < args.count {
                
                let add = args[i+1]
                nodeAddress = add
                
            }
            
        }
        
        if arg.lowercased() == "--threads" {
            
            if i+1 < args.count {
                
                let t = args[i+1]
                threads = Int(t)!
                
            }
            
        }
        
    }
}

if isTestnet {
    nodeAddress = Config.TestNetNodes[0]
}

var comms = Comms(endpoint: nodeAddress)


print("---------------------------")
print("\(Config.CurrencyName) Miner v\(Config.Version)")
print("---------------------------")

print("Connecting to server \(nodeAddress)")
// connect to the server, download the ore seeds and the allowed methods & algos

if isTestnet {
    print("")
    print("********************************************")
    print("** WARNING: RUNNING IN TESTNET MODE       **")
    print("********************************************")
    print("")
}

// test the connection to the node address
let testd = try? Data(contentsOf: URL(string: "http://\(nodeAddress)/")!)
if testd == nil {
    print("Unable to communicate with \(Config.CurrencyName) node @ '\(nodeAddress)'.\nPlease make sure the node is running, and that the port is open on the firewall.\n\nAlternatively, you can use the public node available at public.veldspar.co:14242\n\nTo use another node, please use the command 'miner --node public.veldspar.co --address <- YOUR WALLET ADDRESS HERE ->'")
    exit(0)
}

// generate the ore
oreBlocks[0] = Ore(Config.GenesisID, height: 0)

if walletAddress == nil {
    print("No target wallet address specified, please run the miner with '--address <your wallet id>'")
    exit(0)
}

if !walletAddress!.starts(with: Config.CurrencyNetworkAddress) || walletAddress!.count != 46 {
    print("Invalid wallet address, they will look something like: 'VE3w4fX2DSa4jdDVVfKsCCGW5CGmSb1mAVQVbkt26v6F1p'")
    exit(0)
}

print("\nMining ore .........\n")
print("Using \(threads) threads.")

debug("count of oreBlocks \(oreBlocks.keys.sorted().count)")

for _ in 1...threads {
    
    let oreSize = (((Config.OreSize * 1024) * 1024) - Config.TokenSegmentSize)
    let method = miningMethods[Random.Integer(miningMethods.count)]
    
    Execute.background {
        while true {
            
            let height = oreBlocks[Int(oreBlocks.keys.sorted()[Random.Integer(oreBlocks.keys.count-1)])]!.height
            
            var locations: [UInt32] = []
            for _ in 1...Config.TokenAddressSize {
                locations.append(UInt32(Int(Random.Integer(oreSize))))
            }
            var address = ""
            
            for l in locations {
                let hex = "00000000" + String(l, radix: 16, uppercase: true)
                address += hex.suffix(8)
            }
            
            let t = Token(oreHeight: height, address: address.hexToData, algorithm: method)
            statsLock.mutex {
                hashes += 1
            }
            if t.value() > 0 && t.foundBean() != nil {
                
                print("Found token! @\(Date()) Ore:\(height) method:\(method.rawValue) value:\(Float(t.value()) / Float(Config.DenominationDivider)) bean:\(t.foundBean()!.toHexString())")
                print("Token Address: " + t.tokenStringId())
                
                let r = comms.Register(token: t.tokenStringId(), address: walletAddress!, beanHex: t.foundBean()!.toHexString())
                if r != nil {
                    if r!.success! {
                        print("Token registration successful.")
                    } else {
                        print("Token registration unsuccessful, token already registered :(, or invalid token.")
                    }
                }
                else {
                    print("Token registration unsuccessful, \(Config.CurrencyName) node is not responding or request has timed out.")
                }
                
            }
        }
    }
}

while true {
    sleep(1)
    statsLock.mutex {
        print("Mining rate: \(hashes) h/s")
        hashes = 0
    }
}




