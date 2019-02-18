//    MIT License
//
//    Copyright (c) 2019 Veldspar Team
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
var port: Int = 8080

let args: [String] = CommandLine.arguments

if args.count > 1 {
    for i in 1...args.count-1 {
        
        let arg = args[i]
        
        if arg.lowercased() == "--help" {
            print("---------------------------")
            print("\(Config.CurrencyName) PaperWallet Generator v\(Config.Version)")
            print("---------------------------")
            print("")
            print("\(Config.CurrencyName) - v\(Config.Version)")
            print("-----   COMMANDS -------")
            print("--debug          : enables debug output to console")
            print("--port           : port to run http server on (use nginx to perform SSL proxy for https)")
            exit(0)
        }
        if arg.lowercased() == "--debug" {
            debug_on = true
        }
        if arg.lowercased() == "--port" {
            
            if i+1 < args.count {
                
                let add = args[i+1]
                port = Int(add) ?? 8080
                
            }
            
        }
        
    }
}

print("---------------------------")
print("\(Config.CurrencyName) PaperWallet Generator v\(Config.Version) running on port \(port)")
print("---------------------------")

// now start the webserver and block
RPCServer.start()

let waiter = DispatchSemaphore(value: 0)
waiter.wait()

