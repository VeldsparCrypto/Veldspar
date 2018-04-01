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

class Ore {
    
    private var seedHash: String
    public var material: String = ""
    
    init(_ seed: String) {
        
        seedHash = seed
        
        // recreate the material from the seed, just recursively hash and append a sha512 hash until a significant amount of ore has been generated ready to be mined.  256k feels like enough to produce many billions of combinations of data to mine.
        
        var hashes: [String] = []
        hashes.append(seedHash.sha512())
        for _ in 1...2047 { // 256k block of ore
            hashes.append(hashes[hashes.count-1].sha512())
        }
        
        // feels odd, but this is really highly optimised and works really well.
        material = hashes.joined(separator: "")
        
    }
}
