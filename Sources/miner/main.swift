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
var oreBlocks: [Ore] = []
var payoutAddress: String = ""
var miningMethods: [AlgorithmType] = [AlgorithmType.SHA512_Append]

print("\(Config.CurrencyName) Miner v\(Config.Version)")

print("Connecting to server \(nodeAddress)")
// connect to the server, download the ore seeds and the allowed methods & algos

let seeds = try? CURLRequest("http://\(nodeAddress):14242/blockchain/seeds",.timeout(10)).perform()
if seeds != nil && seeds!.bodyBytes.count > 0 {
    let resObject = try? JSONDecoder().decode(RPC_SeedList.self, from: Data(bytes: seeds!.bodyBytes))
    if resObject != nil {
        for s in resObject!.seeds {
            print("Generating ORE for seed \(s.seed)")
            oreBlocks.append(Ore(s.seed, height: UInt32(s.height)))
        }
    }
}

print("Mining ore .........")

for _ in 1...4 {
    
    Execute.background {
        while true {
            
            let height = oreBlocks[Random.Integer(oreBlocks.count)].height
            let oreSize = (((Config.OreSize * 1024) * 1024) - Config.TokenSegmentSize)
            let method = miningMethods[Random.Integer(miningMethods.count)]
            
            var address: [UInt32] = []
            for _ in 1...Config.TokenAddressSize {
                address.append(UInt32(Random.Integer(oreSize)))
            }
            let t = Token(oreHeight: height, address: address, algorithm: method)
            if t.value() > 0 {
                print("Found token! Ore:\(height) method:\(method.rawValue) value:\(t.value())")
                print("Token Address: " + t.tokenId())
                print("Registering token with network, keep up the good work.")
                //TODO: call node and claim this token as owned by this miner
            }
            
        }
    }
    
}

while true {
    sleep(1)
}




