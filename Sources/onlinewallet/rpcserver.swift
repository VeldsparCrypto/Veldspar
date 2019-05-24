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
import Swifter
 
let banLock: Mutex = Mutex()
var bans: [String:Int] = [:]

let seenBroadcastsLock: Mutex = Mutex()
var seenBroadcasts: [String] = []

enum RPCErrors : Error {
    case InvalidRequest
    case DuplicateRequest
    case Banned
}

class RPCHandler {
    
    class func request(_ request: HttpRequest) -> HttpResponse {
        
        do {
            
            var queryParamsDictionary: [String:String] = [:]
            for o in request.queryParams {
                queryParamsDictionary[o.0] = o.1
            }
            
            var qs = ""
            for k in queryParamsDictionary.keys.sorted() {
                qs += "\(k)=\(queryParamsDictionary[k]!)"
            }
            
            
            switch request.path {
            case "/":
                
                return .ok(.text(Pages.Root("")))
                
            case "/view":
                
                return .ok(.text(Pages.View(request)))
                
            default:
                return .notFound
            }
            
         } catch {
            
            return .internalServerError
            
        }
        
    }
    
}

class RPCServer {
    
    static var this = RPCServer()
    var server: HttpServer = HttpServer()
    
    class func start() {
        
        this.server[""] = { request in
            return RPCHandler.request(request)
        }
        this.server["*"] = { request in
            return RPCHandler.request(request)
        }
        
        do { try this.server.start(UInt16(port), forceIPv4: true, priority: .default) }
        catch {
            logger.log(level: .Error, log: "WORLD IS ON FIRE, Unable to start API server")
            exit(1)
        }
        
    }
    
}

