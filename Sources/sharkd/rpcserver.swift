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
import Foundation
import PerfectHTTP
import SharkCore

func handleRequest() throws -> RequestHandler {
    return {
        
        request, response in
        
        let body = request.postBodyString ?? ""
        var json: JSON = JSON.null
        if body != "" {
            json = try! JSON(data: body.data(using: .utf8, allowLossyConversion: false)!)
        }
        let payload = json.dictionaryObject
        
        response.setHeader(.contentType, value: "application/json")
        response.setHeader(.accessControlAllowOrigin, value: "*")
        response.setHeader(.accessControlAllowMethods, value: "GET, POST, PATCH, PUT, DELETE, OPTIONS")
        response.setHeader(.accessControlAllowHeaders, value: "Origin, Content-Type, X-Auth-Token")
        
        if request.method == .get {
            
            if request.path == "/" {
                do { try response.setBody(json: ["Server" : "\(Config.CurrencyName) Node", "version" : "\(Config.Version)"])} catch {}
            }
            
            if request.path == "/timestamp" {
                do { try response.setBody(json: ["timestamp" : UInt64(Date().timeIntervalSince1970)])} catch {}
            }
            
        } else if request.method == .post {
            
            if payload != nil {
                
                
                
            } else {
                do { try response.setBody(json: ["error": "JSON body was missing"])} catch {}
            }
            
        }
        
        response.completed()
    }
}
