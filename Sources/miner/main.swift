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
import PerfectCURL

#if os(Linux)
srandom(UInt32(time(nil)))
#endif

// defaults
// var nodeAddress: String = Config.SeedNodes[0]
var nodeAddress: String = "127.0.0.1"
var oreBlocks: [Int:Ore] = [:]
var payoutAddress: String = ""
var miningMethods: [AlgorithmType] = [AlgorithmType.SHA512_Append]
var walletAddress: String?
var cacheLock = Mutex()
var threads = 4
var dont_burn = false;

let args: [String] = CommandLine.arguments

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
        if arg.lowercased() == "--dontburncpu" {
            dont_burn = true
        }
        if arg.lowercased() == "--address" {
            
            if i+1 < args.count {
                
                let add = args[i+1]
                walletAddress = add
                
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

print("---------------------------")
print("\(Config.CurrencyName) Miner v\(Config.Version)")
print("---------------------------")

// check for a cache file
var cache = MinerCacheObject()
if FileManager.default.fileExists(atPath: "miner.cache") {
    let cacheObject = try? JSONDecoder().decode(MinerCacheObject.self, from: Data(contentsOf: URL(fileURLWithPath: "miner.cache")))
    if cacheObject != nil {
        cache = cacheObject!
    }
}

print("Connecting to server \(nodeAddress)")
// connect to the server, download the ore seeds and the allowed methods & algos

let seeds = try? CURLRequest("http://\(nodeAddress):14242/blockchain/seeds",.timeout(10)).perform()
if seeds != nil && seeds!.bodyBytes.count > 0 {
    let resObject = try? JSONDecoder().decode(RPC_SeedList.self, from: Data(bytes: seeds!.bodyBytes))
    if resObject != nil {
        for s in resObject!.seeds {
            print("Generating ORE for seed \(s.seed)")
            oreBlocks[s.height] = Ore(s.seed, height: UInt32(s.height))
            cache.ore_cache[s.height] = s.seed
        }
        cache.write()
    } else if (cache.ore_cache.keys.count == 0) {
        // no comms from server, can't mine nothing.
        print("Unable to download ORE from the server located at '\(nodeAddress)', can't continue as cache is also empty.  Please try again later.")
        exit(0)
    }
} else if (cache.ore_cache.keys.count == 0) {
    
    // no comms from server, can't mine nothing.
    print("Unable to download ORE from the server located at '\(nodeAddress)', can't continue as cache is also empty.  Please try again later.")
    exit(0)
    
}

if oreBlocks.keys.count == 0 {
    // restore and generate from the cache
    for k in cache.ore_cache.keys {
        print("Generating ORE for seed (cached) '\(cache.ore_cache[k]!)'")
        oreBlocks[k] = Ore(cache.ore_cache[k]!, height: UInt32(k))
    }
}

if oreBlocks.keys.count == 0 {
    // no ore :(
    print("Unable to download ORE from the server located at '\(nodeAddress)', can't continue as cache is also empty.  Please try again later.")
    exit(0)
}

if walletAddress == nil {
    print("No target wallet address specified, please run the miner with '--address <your wallet id>'")
    exit(0)
}

// trap no communication with server

print("Mining ore .........")

for _ in 1...threads {
    
    Execute.background {
        while true {
            
            let height = oreBlocks[Int(oreBlocks.keys.sorted()[Random.Integer(oreBlocks.keys.count-1)])]!.height
            let oreSize = (((Config.OreSize * 1024) * 1024) - Config.TokenSegmentSize)
            let method = miningMethods[Random.Integer(miningMethods.count)]
            
            var address: [UInt32] = []
            for _ in 1...Config.TokenAddressSize {
                address.append(UInt32(Random.Integer(oreSize)))
            }
            let t = Token(oreHeight: height, address: address, algorithm: method)
            if t.value() > 0 {
                print("Found token! Ore:\(height) method:\(method.rawValue) value:\(Float(t.value()) / Float(Config.DenominationDivider))")
                print("Token Address: " + t.tokenId())
                
                let h = TokenRegistration.Register(token: t.tokenId(), address: walletAddress!, nodeAddress: nodeAddress)
                
                if h == nil {
                    
                    print("Unable to register token with \(Config.CurrencyName) network, caching locally until available.")
                    
                    cacheLock.mutex {
                        // cache this bad boy for later
                        cache.found_tokens[t.tokenId()] = Date()
                        
                        // write out the cache
                        cache.write()
                    }
                    
                } else if (h! > 0) {
                    print("Token successfully registered with \(Config.CurrencyName) node.")
                } else if (h! == -1) {
                    print("Token registration unsuccessful, token already registered :(")
                }
                
                if h != nil && (h! == -1 || h! > 0) {
                    
                    // we had communication just a moment ago so try and flush the cache to the network
                    
                    cacheLock.mutex {
                        if cache.found_tokens.keys.count > 0 {
                            
                            for token in cache.found_tokens.keys.sorted() {
                                
                                let registration = TokenRegistration.Register(token: token, address: walletAddress!, nodeAddress: nodeAddress)
                                
                                if registration != nil {
                                    
                                    if registration! > 0 {
                                        print("Cached token successfully registered with \(Config.CurrencyName) node.")
                                    }
                                    if registration! == -1 {
                                        print("Cached token registration unsuccessful, token already registered :(")
                                    }
                                    
                                    // now remove from the cache
                                    
                                    cache.found_tokens.removeValue(forKey: token)
                                    
                                    cache.write()
                                    
                                }
                                
                            }
                            
                        }
                    }
                }
            }
            if dont_burn {
                Thread.sleep(forTimeInterval: 0.005)
            }
        }
    }
}

while true {
    sleep(1)
}




