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
import CryptoSwift

/*
 *      The Economy class will take tokens and verify their value, based on the complexity of the workload used to produce it.
 */

public class Economy {
    
    /*
     
     After many...many iterations of reward for PoW systems, we always ended up with far too many smaller values.  This became problematic, because to send a transaction would mean the reallocation of 1000's of small value tokens.  We needed the reward to be almost entirely random but also marginally weighted to the smaller values for numerance.
     
     So, having been round and round the differing concepts, we decided to just go with the "magic beans" approach.  So still entirely luck based, but will produce what the system needs in a wide spread of values.
     
     below is the code:
     
             // 1's, 2's & 5's are more numerous, but allocation is still entirely random.
             let values: [Int] = [1,1,1,1,1,1,2,2,2,2,2,2,5,5,5,5,5,5,10,10,10,10,50,50,50,100,100,500,1000,2000,5000]
             let alphabet = ["1","2","3","4","5","6","7","8","9","0","a","b","c","d","e","f"]
             var results: [String:Int] = [:]
     
             while results.keys.count < 1000 {
     
             let key = alphabet[Int(arc4random_uniform(15))] +  alphabet[Int(arc4random_uniform(15))] + alphabet[Int(arc4random_uniform(15))] + alphabet[Int(arc4random_uniform(15))] + alphabet[Int(arc4random_uniform(15))] + alphabet[Int(arc4random_uniform(15))]
             let value = values[Int(arc4random_uniform(UInt32(values.count)))]
     
             results[key] = value
     
             }
     
             print(results)
     
     */
    
    // the byte chosen to determin minable hashes.  So looking for a hash starting 0xffffff for instance.
    static let patternByte = UInt8(255)
    
    // the 'magic beans' table, is an assortment of random sequences which have value.  This stops the programatic discovery of only small value tokens.  Which would result in transactions which are far too numberous (e.g. sending 1000 veldspar would result in 10,000 token re-allocations)
    static let magicBeans : [AlgorithmType : [Int /* active block height */ : [String:Int]]] =
        [
            AlgorithmType.SHA512_Append : [ 0 :
                ["68296c": 5, "d2c99c": 1, "7c4493": 1, "931890": 10, "933ec7": 50, "0aeb6d": 2, "8d0338": 1, "31d512": 500, "bb8585": 5, "30c69b": 2000, "b6e5e6": 5, "1b9493": 500, "44c15e": 5, "8bdb96": 5, "50a4d3": 2, "9cc4c6": 500, "e68be3": 2, "6d62c4": 2, "4ac63e": 2, "13caec": 50, "a61e43": 1, "c9d6c8": 10, "de6677": 50, "7a1382": 10, "b1bda4": 5, "151969": 2000, "7b2c42": 5, "447a01": 2, "927cb3": 2000, "5d835d": 1, "bb5860": 5, "754974": 2, "a1c6e4": 2, "514592": 2, "e7bb6c": 1, "7a7549": 2, "20da0c": 5, "29c008": 10, "c9d861": 10, "d5547e": 1, "e3b304": 5, "24ea73": 100, "accd6c": 10, "73bc48": 2, "325614": 2, "44d47d": 50, "ce45c6": 5, "988859": 2, "8ab65c": 1, "2dad00": 500, "ccd852": 1, "d3c798": 5, "2bd89e": 2, "42a716": 2, "515287": 500, "c8559e": 10, "3dadbe": 1, "3d2d98": 1, "2c6c29": 500, "956751": 5, "228e59": 2, "eadc51": 100, "245a6c": 1, "068141": 5, "b59d01": 1000, "61451b": 10, "8a8040": 100, "28d57d": 5, "28bb05": 2, "0c0e2d": 2, "b76225": 2, "4792b4": 2, "ec98eb": 5, "49e379": 5, "c541a2": 10, "8dbd6c": 2, "0255ab": 5, "93796a": 1, "d82e27": 2, "e8dc04": 5, "076c81": 10, "c23c00": 5, "807745": 2, "9d24b3": 1000, "db969a": 50, "84775d": 50, "b65282": 50, "42a37c": 1, "16c052": 10, "9a7d71": 1, "b25a33": 5, "246d93": 5, "1e4370": 5, "8c4304": 1000, "68dc7c": 2, "18800d": 2000, "2dc81c": 5, "d48110": 1, "93e38c": 5, "cbcb37": 5000, "684d5b": 1000, "a0839b": 1, "a73cd7": 1, "2ea1d2": 2, "5822ad": 1, "08d614": 1, "9c592e": 50, "6b49c8": 1, "029632": 5, "e19d90": 1, "4b26c2": 50, "9edcb2": 5, "03603a": 10, "adb8aa": 1, "9324c7": 1, "c3db43": 2, "175c82": 2, "8329db": 10, "367d6b": 1, "90439e": 1, "197384": 2, "89ad82": 10, "d41342": 2, "37834a": 5000, "382e94": 100, "77d37e": 5, "4e30b6": 1, "b07a89": 2, "4eb0e9": 1, "aeca17": 100, "c282d0": 5000, "00338d": 2, "781350": 2, "4ac85a": 2, "859814": 100, "5762e7": 500, "03e7eb": 10, "8b2e18": 500, "068ae2": 50, "d234a8": 5, "197851": 1, "d6bd6b": 2, "bb32e6": 500, "2cb4b0": 5, "b51256": 2, "cc8478": 5000, "560569": 10, "5e1400": 50, "4d6384": 100, "4e96ae": 10, "657766": 1, "7161e9": 1, "a92023": 2, "4a7591": 10, "dace53": 2, "59a96b": 1, "44cc7b": 5, "6b0243": 10, "27ba66": 100, "2200ec": 5, "8e80a0": 1, "b51b2a": 5, "16d9eb": 100, "ec6217": 50, "8e4430": 100, "748343": 10, "d7c561": 10, "8c39e6": 1, "a63b64": 1, "2c10c1": 5, "4c49d5": 50, "c3c3d5": 500, "b048eb": 50, "da081b": 5, "5bb3ba": 10, "a11bbe": 100, "703b8e": 50, "154dd8": 10, "d90e80": 2, "1b4566": 1, "c8d479": 5000, "06ec3b": 5, "52e2bd": 5, "abae55": 1, "03271b": 10, "50862e": 2000, "c4ecca": 5, "d8a6e2": 2, "249beb": 100, "609c73": 1, "9651a1": 1, "a08613": 2, "de83c3": 500, "9a4ac1": 5000, "cd89e1": 1, "a2b07c": 1, "a802d5": 5, "9c0b96": 5000, "314e52": 2, "7d8ce2": 2, "c816ea": 2, "c9dbd7": 5000, "569d93": 2, "926804": 5, "ac57d9": 50, "65643d": 10, "b280e7": 50, "99b312": 2, "173d0b": 10, "6d2278": 5, "889b7e": 1, "25d722": 50, "2a5cdc": 1, "36bcce": 2, "72015c": 50, "a7cc07": 1, "d485bb": 5000, "a24191": 50, "729a8b": 50, "a39503": 2, "22d9d2": 1, "ba3b35": 5, "8833a1": 2, "c3cad0": 10, "ceb89d": 10, "4e4ac0": 2, "b89288": 500, "9938b8": 100, "34c942": 1, "03ca3e": 500, "5d0002": 2, "30c648": 5, "21e61c": 2, "3e7404": 50, "169322": 2, "5cca32": 2, "e5775a": 1, "08e5e4": 5000, "6a1214": 1, "7998a8": 1, "99e8c6": 50, "0eb380": 10, "4d511c": 10, "b70a0a": 2, "b55a5a": 50, "390286": 1, "1c7a83": 50, "540282": 5, "1d9c47": 5, "792229": 500, "a153de": 5000, "4366a3": 1, "5289e0": 1, "db17e0": 2, "4ed990": 10, "223ac3": 10, "05b13d": 1, "4e0534": 50, "9dab5e": 1, "e664bd": 5, "6a49d8": 2, "0013b4": 2000, "318359": 10, "151c2d": 1, "0ba290": 2, "ad446a": 5, "5addd9": 1, "07d68b": 2000, "4ad921": 10, "1c1838": 5, "a323e6": 5, "18473d": 5, "a523ab": 1, "627272": 5, "c30d85": 2, "95d8dd": 5, "8c77dd": 10, "c3ce82": 2, "ad524b": 5, "c3a40e": 5, "2932c6": 1, "48b9ea": 100, "b56867": 10, "bb8a71": 2, "1891b6": 2, "60629b": 5000, "e570c0": 5, "7683c4": 500, "9103e3": 5000, "263d1a": 50, "5b8273": 1, "20a542": 2, "c0193c": 100, "dcd7e1": 2, "ae1c62": 1, "d7b099": 1, "d2ac3b": 5, "786aa7": 100, "a6161b": 1, "45a0c8": 5, "4d863e": 10, "9183b7": 10, "9b10b0": 5, "0a50a8": 50, "2edd03": 5, "664a6c": 2, "09adce": 1, "ccb69e": 100, "c819e4": 2, "b76c75": 10, "de8ca7": 2, "0470ce": 1, "53800c": 500, "d823bd": 2, "c21574": 100, "a296d5": 5000, "196252": 500, "942715": 5, "3231a9": 5000, "e56863": 10, "7c539a": 1, "94b054": 1000, "788328": 2, "77d4a9": 1000, "7d6024": 5000, "1db717": 100, "dd98c9": 2, "a3c16b": 5, "589d06": 2, "25a547": 5, "eeed08": 1, "cce55e": 10, "98509b": 1, "14365b": 2, "323739": 2, "8013d4": 2, "76707a": 500, "224b33": 10, "62b766": 5000, "393c7b": 50, "83290e": 10, "db4739": 10, "24804c": 1, "68116c": 5, "2e8896": 2000, "51ed57": 10, "7521d7": 5, "55628e": 1, "616334": 5, "085900": 10, "ab520e": 10, "1abe19": 1000, "9587d6": 100, "711a75": 5000, "881106": 10, "d19094": 100, "a9d016": 5, "bb319c": 2, "e166e9": 2000, "2a3c14": 5, "759ba7": 2, "18a11c": 50, "66cd8e": 1, "775d26": 100, "b5e19d": 2, "ada837": 5000, "8958a4": 5, "b6c43e": 5, "3c79aa": 1, "501d35": 2000, "4e3953": 100, "40678b": 1, "39957c": 2000, "ba255e": 5, "100424": 5, "41884b": 50, "5b8b61": 2, "9409e5": 5, "9b03c3": 1, "7873ec": 1, "337a2c": 5, "e369c0": 5, "71319d": 1, "55ac93": 2000, "33a7cd": 2, "c60b88": 10, "51b484": 2, "2c3b9a": 100, "358493": 10, "3c3d3d": 10, "b01697": 2, "52e545": 2, "d995c1": 5, "22cabe": 100, "da6cc5": 10, "7ba3eb": 50, "25a166": 5, "4ce550": 100, "25205e": 50, "cd671b": 1, "964065": 100, "27c07b": 1, "4ed641": 1, "619aba": 1, "1d4299": 5, "b08bb9": 2000, "5c785b": 1, "3e36a4": 2, "63939e": 2, "8be2d5": 50, "1cc663": 1, "a4136c": 50, "6e2770": 1, "b14764": 10, "76028b": 2, "7b5ded": 100, "e996e6": 500, "cb29c1": 1, "4b934d": 1, "335625": 50, "13ee4e": 5, "23de41": 1, "1beec9": 1, "280502": 10, "4e9783": 50, "a995a5": 1, "a74a8c": 1, "83a2d4": 2, "9e912a": 50, "b87178": 1, "eaedeb": 1, "7b8303": 10, "18174e": 1, "88a3bc": 1, "d93d41": 1, "103c25": 10, "8b2786": 1, "36c4e3": 100, "c19aa9": 1, "794da7": 10, "9538d8": 5000, "b2aee2": 1, "ce6302": 2, "1bae41": 2, "7c196d": 2, "66c61a": 1, "0808b2": 5, "46941e": 5, "3aea46": 1, "93bb8d": 5, "75b56e": 1, "30e6ac": 1, "59c05d": 5, "47971e": 1, "eec3b3": 2, "ec9552": 5, "0860a5": 1, "5ece05": 1, "35a4bb": 2, "346435": 5, "7d7dd6": 500, "dc755e": 50, "986cca": 50, "9bdb27": 1, "49323a": 2, "1e0a39": 1, "42dac7": 5, "be3101": 50, "ba3b4a": 50, "c4a5bb": 50, "a8b011": 2, "9c99ee": 1, "521e52": 5, "b544e2": 100, "4e0ae9": 2, "e3793c": 2, "5c73e0": 100, "b5c056": 10, "b71db2": 5, "891a91": 5000, "62a40e": 10, "605eac": 100, "db1858": 10, "c4aa51": 1, "99e9c5": 2, "2c2c6b": 10, "e77a84": 2000, "6cc534": 1, "59be31": 1, "283631": 5, "5a9598": 5, "861576": 5, "8a11a4": 50, "0bd61d": 2, "54787b": 100, "977272": 50, "5c1bab": 5000, "d42485": 10, "a66b82": 50, "a5ca70": 5000, "b7eb00": 10, "42c1c7": 5000, "9a2eee": 5, "173278": 5, "b252d1": 2000, "0972a3": 500, "86ce78": 50, "b3c470": 1000, "a52096": 1, "443cc3": 5, "61b077": 500, "4e8467": 2, "a55952": 5, "1e4ed8": 2, "b72723": 5000, "26010d": 2000, "0144ea": 2000, "61765d": 1, "88d697": 100, "241490": 500, "ee75c5": 1, "c5a4cc": 5, "871e07": 5, "e267a4": 2, "230140": 2000, "e55ded": 2, "088b58": 2000, "179ad9": 50, "be5d96": 10, "eb09e7": 5, "aa53b3": 1000, "3db57d": 5, "cbaea7": 1, "c349d7": 1, "53968e": 5000, "ed07b0": 5, "b15b41": 1, "112a47": 1, "5a8536": 100, "b84935": 1000, "5c8121": 5, "be1eca": 1, "3dadee": 5000, "d90b64": 5, "a927dd": 1, "b5a820": 1000, "4c272b": 2, "a3142a": 10, "05570d": 50, "978255": 2, "ebcd30": 5000, "283b0a": 2, "1eca72": 1, "501be0": 5, "dd64d1": 1, "4baa47": 1000, "47d70b": 10, "d88162": 50, "8b7511": 50, "676775": 50, "1927d1": 100, "5532b5": 1, "788a9b": 500, "8aee61": 2, "6815e0": 1, "5e2602": 1, "9229b7": 2, "c18b40": 2000, "1bba9c": 1, "2657ae": 5, "bdd3c0": 2, "c76899": 1, "b0cedb": 1, "a2d99e": 1, "c3d1c2": 2, "196527": 10, "a8c0e7": 50, "a5e7a6": 2, "65e9a5": 5, "6b07b4": 5, "3ab68c": 2000, "dc39d0": 10, "528722": 1, "b51c53": 2, "b46498": 500, "e60c2a": 1, "4bb097": 5, "55c46e": 1, "d9b18c": 2, "14a079": 2, "e8a304": 2000, "6253ca": 1000, "301e99": 1, "b0c695": 10, "331269": 10, "68ae48": 5, "4a529b": 5000, "aa62db": 2, "889a41": 1, "c0198e": 5, "367e85": 5, "c1accb": 5, "b72287": 2, "b59c18": 10, "060596": 1, "dd9c54": 5, "5c3098": 5, "1dcb9a": 50, "766d2d": 2, "1e3472": 5000, "d2565b": 100, "d950c2": 1, "29490c": 50, "820758": 2, "78506b": 5, "2032d9": 100, "6bee06": 5000, "00eaec": 2000, "aee6e6": 50, "75e552": 1000, "1b9948": 2, "e64e92": 1, "81080e": 500, "08e385": 100, "949560": 2, "8cee76": 1000, "4071be": 10, "dd53cb": 2, "3e025e": 5000, "99c8d2": 5, "6e565d": 5000, "a67b79": 50, "46b5e3": 1, "3a76b5": 2, "98b6ec": 50, "3c6247": 5, "e9c325": 2000, "d25249": 2, "6c5403": 50, "c2b878": 5, "57e3a2": 2, "d5a6dc": 2, "9e57b6": 2, "3d4ce5": 1, "1d31a8": 500, "483313": 5, "415871": 10, "815e76": 2, "1cdd1d": 1, "898202": 10, "338dd8": 100, "7ebc41": 5, "2e7360": 5, "eedd1d": 1, "7431b8": 2, "135a13": 1, "e620d1": 100, "5571c4": 1000, "2476d7": 2000, "0c8a40": 100, "6b0b90": 10, "d8588d": 50, "6d4481": 1, "a93150": 10, "a603dd": 2, "e6b75c": 2, "38c4a2": 5, "4b261e": 500, "8c83db": 1, "b171ca": 100, "66b5ae": 2, "89e9ba": 5, "74b32b": 5, "b0717e": 5, "3591d0": 50, "18e143": 2000, "947ba3": 1, "331d08": 1, "9715da": 1, "9dea26": 100, "7be016": 100, "59d139": 50, "1ee987": 2, "3306ad": 50, "7d015d": 5, "4ad4a0": 2, "720d89": 2, "06c5e6": 5, "d77199": 5, "bea96a": 2000, "8261d2": 10, "8a1de5": 1, "902289": 5, "27aa25": 1000, "724ae2": 100, "e94b03": 100, "a826a2": 10, "b660d9": 10, "449d14": 2, "9c5b4a": 2, "6402b7": 10, "a15d7a": 2, "2d37c9": 1, "20110b": 1, "642b51": 1, "78cc67": 100, "2a286d": 2000, "dc3c25": 1000, "929598": 5, "7064a7": 1000, "2a3768": 100, "901866": 10, "a675cc": 5, "7aee8a": 500, "b63b13": 1, "d47838": 1, "3a5da7": 1, "29de8b": 2000, "a74206": 1, "ed933d": 50, "74a915": 500, "5a7338": 2, "79d3cb": 100, "232d2a": 2000, "8ab4b8": 10, "0a01a0": 5000, "538d0d": 2, "b62135": 100, "270a7d": 2, "53b006": 1, "6da1bb": 5, "62cb38": 1, "6718be": 2, "98e5c3": 100, "435cc9": 2, "3e0a1c": 10, "ccc8ce": 2000, "430bed": 1, "30642d": 2, "690082": 1, "45e78e": 1, "ced86e": 100, "ac9779": 100, "b5b701": 1, "605754": 5, "3b2eae": 2, "e45bc9": 2, "0da87b": 5, "acaca3": 10, "6a5b2c": 1, "00b583": 5, "39ad87": 1, "1d9847": 5, "da7638": 5, "37e203": 10, "37b247": 5000, "2ecbea": 10, "08427b": 1, "cd95dd": 50, "8b6000": 2, "6938d8": 5, "1840a8": 1, "60c03b": 50, "3b186d": 100, "c84b17": 100, "337d97": 5, "225bbd": 50, "3eca5a": 5, "8c7be7": 100, "0547ad": 2, "09bc5a": 2, "ca10d8": 50, "77d296": 2, "957d16": 1, "68a9d9": 2, "643dc3": 2, "2b46d0": 5, "285d95": 2, "9826e0": 2, "24b74e": 2000, "be10ea": 2000, "de5730": 2000, "d23174": 5, "90c6ac": 5, "d0e0a0": 2, "56d83b": 5, "d13990": 5, "e53911": 100, "d2eb01": 5, "857535": 1, "c8341b": 1000, "7a65b3": 5000, "d7c0bd": 2, "4d560a": 5, "41681d": 1, "596b62": 100, "7b9d51": 50, "a4d735": 10, "57025d": 1, "cbe2e2": 100, "e61040": 10, "85b6b8": 50, "541294": 1, "3e23a2": 50, "915d05": 100, "b698be": 2, "d89486": 2, "7009a0": 50, "e8683b": 5, "634dea": 5, "985a92": 1, "d3180d": 1, "d2dc02": 100, "964c53": 5, "2b378a": 1, "b4c462": 1, "c076ec": 10, "54a857": 50, "966e3a": 5000, "12c420": 1, "c79890": 2000, "8008a4": 10, "b8157d": 5, "161d8e": 2, "5d1ddd": 2, "98642e": 5, "972404": 1, "aecdec": 2000, "dc1885": 1, "9e333c": 1, "8a7a0e": 5, "6dc986": 2, "61e58d": 2, "6b0503": 1, "218bb2": 10, "26b9aa": 5000, "16b7b9": 5, "3c8987": 2, "cad665": 100, "b7dcde": 10, "a162c1": 1, "26cb6c": 100, "4ec1e5": 1, "9e1ad2": 10, "e7bcc2": 50, "a6bbc8": 1, "42de18": 50, "6793ab": 100, "994e43": 2000, "41d69b": 500, "07910d": 2, "37377c": 5000, "116349": 2, "2ae056": 2, "d362b8": 1000, "77125c": 1, "212031": 2, "5c5d29": 5, "68acb5": 50, "a94b66": 10, "6e6703": 50, "3a5125": 5, "1be3e9": 5, "de0967": 1, "351a80": 5, "c53312": 2, "d82bd0": 50, "94a5dc": 50, "6e1a67": 2, "ded7c2": 2, "23d77a": 5, "a66817": 1, "3d5883": 50, "d02511": 10, "7a9301": 1, "b81a87": 1000, "a57442": 5, "eb4e0d": 2, "93e0be": 2, "23e6ab": 1, "5357dd": 5, "2adc3e": 2, "9684c7": 1000, "3b6a88": 10, "497202": 5, "45d3eb": 100, "e479b4": 5, "76bcee": 1, "d50b63": 2, "0412cd": 1, "b9be36": 1, "d3e8ee": 5, "36519d": 10, "123ad2": 2, "d9172c": 2, "b7e537": 100, "77749d": 500, "2576c5": 5, "85e211": 100, "d78d92": 1, "8b6039": 100, "81119a": 5000, "e0718d": 5000, "c33ed7": 10, "952944": 2, "4b4931": 5, "7bb65b": 5, "47a91c": 1000, "534e6b": 2, "6e0026": 5, "413a7e": 2000, "82736a": 2, "94833a": 5000, "0c6360": 2, "6564cc": 2, "000192": 2000, "99444d": 100, "e9bde1": 2, "20b2d2": 5, "54635e": 50, "244232": 2, "ea2104": 5, "323c82": 2, "7c1800": 1, "530aa2": 2, "145e26": 2000, "262726": 100, "5e4643": 50, "0e0091": 1, "5c2426": 1, "4c3b29": 1, "54bbb2": 10, "53a432": 5000, "62d2c8": 1, "52d857": 50, "6e4a87": 50, "de5c0b": 2, "148587": 10, "8568c6": 500, "e8bdd2": 1000, "13e5c0": 10, "779278": 100, "0c0e50": 1, "5ac32d": 1, "e8a9b3": 1, "9a91a2": 2000, "074297": 5, "cc1cd5": 5, "3481ac": 100, "87bd1b": 500, "8b949e": 50, "c206db": 100, "039c6c": 5, "30e2cb": 2, "88d7dd": 50, "a011e5": 5, "d1d5bd": 1, "25b798": 1, "30b9b0": 5, "1b922c": 500, "5d7769": 1, "a713de": 10, "a0ae30": 500, "eba0ed": 2, "2772ce": 2, "7728d5": 50, "583ce3": 5, "808581": 2, "e8662c": 100, "24de74": 50, "82907c": 2, "e9191d": 2, "bd3294": 10, "30aa7e": 5, "349b2a": 10, "51eb74": 1, "433571": 100, "481964": 1, "572138": 1, "3a7858": 1, "3ee755": 10, "0a3170": 2, "ca2c26": 100, "007667": 2, "455361": 2, "b779a4": 2, "8b4eb0": 2, "8639a3": 10, "258e9b": 2, "6c14ac": 5, "12dc3a": 5, "a76068": 10, "bb4916": 2000, "08b5de": 10, "5325c0": 1, "18b550": 10, "22778c": 5, "721529": 10, "4290cb": 5, "858b7c": 1]

            ]
    ]
    
    public class func value(token: Token, workload: Workload) -> UInt32 {
        
        var value = 0
        
        // value can be differentiated by many things, so switch on the implementation to start
        switch token.algorithm {
        case .SHA512_Append:
            
            // find the beans table appropriate to the ore height
            let algoTable: [Int /* active block height */ : [String:Int]] = magicBeans[AlgorithmType.SHA512_Append]!
            
            
            
            
        }
        
        return UInt32(value)
        
    }
    
}
