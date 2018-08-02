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

enum OreErrors : Error {
    case OreDoesNotExist
}

public class Ore {
    
    // global ore cache, to be implemented in ram and generated/loaded from disk.

    static private var cache: [UInt32:Ore] = [:]
    static private var cacheLock: Mutex = Mutex()
    private var seedHash: String
    
    public var rawMaterial: [UInt8] = []
    public var height: UInt32

    public init(_ seed: String, height: UInt32) {
        
        self.height = height
        self.seedHash = seed
        
        // recreate the material from the seed, just recursively hash and append a sha512 hash until a significant amount of ore has been generated ready to be mined.
        
        var hashes: [[UInt8]] = []
        hashes.append(Array(seedHash.utf8).sha512())
        for _ in 1...(((Config.OreSize * 1024) * 1024) / Array(seedHash.utf8).sha512().count) {
            hashes.append(hashes[hashes.count-1].sha512())
        }
        
        // feels odd, but this is really highly optimised and works really well.
        for a in hashes {
            rawMaterial.append(contentsOf: a)
        }
        
        // check this into the cache for use throuought the codebase
        Ore.cacheLock.mutex {
            Ore.cache[height] = self
        }
        
    }
    
    public class func atHeight(_ height: UInt32) throws -> Ore {
        
        var o: Ore? = nil
        Ore.cacheLock.mutex {
            o = Ore.cache[height]
        }
        
        if o == nil {
            throw OreErrors.OreDoesNotExist
        }
        
        return o!
        
    }
}
