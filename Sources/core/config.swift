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

public class Config {
    
    public static let Version = "0.2.0 beta"
    public static let CurrencyName = "Veldspar"
    public static let CurrencyNetworkAddress = "VE"
    public static let GenesisID = "0fcbb8951fd052764f71a634b02361448386c5b0f70eadb716cc0f3f"
    public static let BlockchainStartDate = 1543611714000
    
    public static let MagicByte = UInt8(255)
    
    public static let DefaultHashType: CryptoHashType = .sha224
    
    // transaction maturity level - targets transactions for x number of blocks in the future to allow a consensus network to operate
    public static let TransactionMaturityLevel = 1
    
    // number by which token value is divided to determine currency value
    public static let DenominationDivider = 100
    
    // regularity of block formation
    public static let BlockTime = 60 * 1 // 1 minute, because it is not a traditional coin and there is no real downside to slower and more durable blocks.
    
    // size of the ore segment in megabytes - 1mb gives posibilities of 1.169e^57 combinations @ address size of 8
    public static let OreSize = 1
    
    public static let TokenSegmentSize = 64
    
    // the network transfer fee in raw units
    public static let NetworkFee = 2 // 0.02
    
    // the community fund address where the network fee ends up.  Some will be burnt, some will be used to pay community members for tasks, some will be used as a money exchange system.
    public static let CommunityAddress: String? = nil
    
    // number of addresses within the block that makes up a token address, exponentially increses ore payload
    public static let TokenAddressSize = 3
    
    // seed nodes
    public static let SeedNodes: [String] = ["primary.veldspar.co:14242"]
    public static let TestNetNodes: [String] = ["testnet.veldspar.co:14242"]

    
}
