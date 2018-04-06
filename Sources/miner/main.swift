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

print("\(Config.CurrencyName) Miner v\(Config.Version)")

let o = Ore("test", height: 1)

var hit = 0
var miss = 0
var total: UInt32 = 0
var lock = Mutex()
var hashes = 1000000

func getHashesRemaining() -> Int {
    var r = 0
    lock.mutex {
        r = hashes
    }
    return r
}

func decrementHashes() {
    lock.mutex {
        hashes -= 1
    }
}

for _ in 1...8 {
    
    Execute.background {
        while getHashesRemaining() > 0 {
            
            var address: [UInt32] = []
            for _ in 1...8 {
                address.append(UInt32(arc4random_uniform(UInt32((Config.OreSize*1024)*1024)-UInt32(Config.TokenSegmentSize))))
            }
            let t = Token(height: o.height, address: address, algo: .sha512, method: .append)
            if t.value > 0 {
                lock.mutex {
                    hit+=1
                    total+=t.value
                    print("hit : \(hit), miss : \(miss), total : \(total)")
                    print(t.tokenId())
                }
            } else {
                lock.mutex {
                    miss+=1
                }
            }
            decrementHashes()
            
        }
    }
    
}

while getHashesRemaining() > 0 {
    Thread.sleep(forTimeInterval: 10)
    lock.mutex {
        print("hit : \(hit), miss : \(miss), total : \(total)")
    }
}
lock.mutex {
    print("hit : \(hit), miss : \(miss), total : \(total)")
}



