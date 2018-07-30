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
import SharkCore
import Ed25519

#if os(Linux)
    srandom(UInt32(time(nil)))
#endif

// defaults
var nodeAddress: String = "127.0.0.1:14242"
var oreBlocks: [Ore] = []
var payoutAddress: String = ""
var miningMethods: [AlgorithmType] = [AlgorithmType.SHA512_Append]

print("\(Config.CurrencyName) Miner v\(Config.Version)")

print("Connecting to server \(nodeAddress)")
// connect to the server, download the ore seeds and the allowed methods & algos
// TODO: Network call

print("Generating ORE, this may take some time ........")
oreBlocks.append(Ore("test", height: 1))
oreBlocks.append(Ore("my", height: 2))
oreBlocks.append(Ore("balls", height: 3))

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




