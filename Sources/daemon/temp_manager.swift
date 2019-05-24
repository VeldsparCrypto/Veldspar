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

class TempManager {
    
    var TEMP_PATH = "./temp"
    var TEMP_PATH_INBOUND = "./temp/inbound"
    var TEMP_PATH_INBOUND_INT = "./temp/inbound/int"
    var TEMP_PATH_INBOUND_REG = "./temp/inbound/reg"
    var TEMP_PATH_INBOUND_TFR = "./temp/inbound/tfr"
    var TEMP_PATH_OUTBOUND_BROADCAST = "./temp/outbound"
    var TEMP_PATH_TIDEMARK = "./temp/tidemark"
    
    var lock_inbound = Mutex()
    var lock_outbound = Mutex()
    var lock_index = Mutex()
    
    var nextValue: UInt64? = nil
    
    var inboundItems: [String:[String]] = [:]
    
    init() {
        
        try? FileManager.default.createDirectory(atPath: TEMP_PATH, withIntermediateDirectories: true, attributes: nil)
        try? FileManager.default.createDirectory(atPath: TEMP_PATH_INBOUND, withIntermediateDirectories: true, attributes: nil)
        try? FileManager.default.createDirectory(atPath: TEMP_PATH_INBOUND_INT, withIntermediateDirectories: true, attributes: nil)
        try? FileManager.default.createDirectory(atPath: TEMP_PATH_INBOUND_REG, withIntermediateDirectories: true, attributes: nil)
        try? FileManager.default.createDirectory(atPath: TEMP_PATH_INBOUND_TFR, withIntermediateDirectories: true, attributes: nil)
        try? FileManager.default.createDirectory(atPath: TEMP_PATH_OUTBOUND_BROADCAST, withIntermediateDirectories: true, attributes: nil)
    }
    
    fileprivate func NextIdentifier() -> UInt64 {
        
        var i: UInt64 = 0
        
        lock_index.mutex {
            
            if self.nextValue == nil {
                let data = try? Data(contentsOf: URL(fileURLWithPath: self.TEMP_PATH_TIDEMARK))
                if data != nil {
                    self.nextValue = data!.withUnsafeBytes { (ptr: UnsafePointer<UInt64>) -> UInt64 in
                        return ptr.pointee
                    }
                } else {
                    self.nextValue = 1
                }
            }
            
            i = self.nextValue!
            self.nextValue! += UInt64(1)
            var mutableValue = self.nextValue!
            
            // thread off this update to a serial queue
            Execute.background {
                Execute.serial {
                    // write the new value to disk
                    let data = withUnsafeBytes(of: &mutableValue) { Data.init($0) }
                    try? data.write(to: URL(fileURLWithPath: self.TEMP_PATH_TIDEMARK))
                }
            }
            
        }
        
        return i
        
    }
    
    func putInterNodeTransfer(_  data: Data, src: String?) {
        
        putTempItem(data, identifier: NextIdentifier(), path: TEMP_PATH_INBOUND_INT, type: "int", src: src)
        
    }
    
    func putBroadcastOut(_  data: Data) {
        
        putTempItem(data, identifier: NextIdentifier(), path: TEMP_PATH_OUTBOUND_BROADCAST, type: "int", src: nil)
        
    }
    
    func putRegister(_  data: Data, src: String?) {
        
        putTempItem(data, identifier: NextIdentifier(), path: TEMP_PATH_INBOUND_REG, type: "reg", src: src)
        
    }
    
    func putTransfer(_  data: Data, src: String?) {
        
        putTempItem(data, identifier: NextIdentifier(), path: TEMP_PATH_INBOUND_TFR, type: "tfr", src: src)
        
    }
    
    func putTempItem(_  data: Data, path: String, name: String) {
        
        // now write the request on a background thread, as it is not neccesary to block whilst this happens
        Execute.background {
            
            let u = URL(fileURLWithPath:  "\(path)/\(name)")
            
            do {
                // attempt to write the temp file
                try data.write(to: u)
            } catch {
                logger.log(level: .Error, log: "Failed to write broadcast record to '\(u)'")
            }
            
        }
        
    }
    
    func putTempItem(_  data: Data, identifier: UInt64, path: String, type: String, src: String?) {
        
        // now write the request on a background thread, as it is not neccesary to block whilst this happens
        Execute.background {
            
            let idno = "00000000000000000000\(identifier)".suffix(12)
            
            let u = URL(fileURLWithPath:  "\(path)/\(idno).\(type)")
            
            do {
                // attempt to write the temp file
                try data.write(to: u)
                if src != nil {
                    try? src?.write(toFile: "\(path)/\(idno).src", atomically: true, encoding: .ascii)
                }
            } catch {
                logger.log(level: .Error, log: "Failed to write broadcast record to '\(u)'")
            }
            
        }
        
    }
    
    func popIntInbound() -> Data? {
        
        var d: Data?
        
        lock_inbound.mutex {
            d = self.popTempItem(path: self.TEMP_PATH_INBOUND_INT, type:"int")
        }
        
        return d
    }
    
    func popRegister() -> Data? {
        
        var d: Data?
        
        lock_inbound.mutex {
            d = self.popTempItem(path: self.TEMP_PATH_INBOUND_REG, type: "reg")
        }
        
        return d
    }
    
    func popTransfer() -> Data? {
        
        var d: Data?
        
        lock_inbound.mutex {
            d = self.popTempItem(path: self.TEMP_PATH_INBOUND_TFR, type:"tfr")
        }
        
        return d
    }
    
    func popIntOutBroadcast() -> Data? {
        
        var d: Data?
        
        lock_inbound.mutex {
            d = self.popTempItem(path: self.TEMP_PATH_OUTBOUND_BROADCAST, type:"int")
        }
        
        return d
    }
    
    func peekTempItem(path: String, type: String) -> (fileId: String, data: Data)? {
        
        do {
            
            let firstfile = try FileManager.default.contentsOfDirectory(atPath: path).sorted().first
            if firstfile != nil {
                if firstfile!.hasSuffix(type) {
                    let d = FileManager.default.contents(atPath: "\(path)/\(firstfile!)")
                    if d != nil {
                        try FileManager.default.removeItem(atPath: "\(path)/\(firstfile!)")
                        return (firstfile!, d!)
                    }
                }
            }
            
        } catch {
            
            logger.log(level: .Error, log: "Unable to open file error '\(error)'")
            return nil
            
        }
        
        return nil
        
    }
    
    func popTempItem(path: String, type: String) -> Data? {
        
        do {
            
            if inboundItems[path+type] == nil {
                inboundItems[path+type] = []
            }
            
            if inboundItems[path+type]!.count == 0 {
                
                let sortedItems = try FileManager.default.contentsOfDirectory(atPath: path).sorted()
                for i in sortedItems {
                    if !i.hasSuffix("src") {
                        if i.hasSuffix(type) {
                            inboundItems[path+type]!.append(i)
                        }
                    }
                }
                
            }
            
            if inboundItems[path+type]!.count > 0 {
                for idx in 0...inboundItems[path+type]!.count-1 {
                    let firstfile = inboundItems[path+type]![idx]
                    if firstfile.hasSuffix(type) {
                        let d = FileManager.default.contents(atPath: "\(path)/\(firstfile)")
                        if d != nil {
                            try FileManager.default.removeItem(atPath: "\(path)/\(firstfile)")
                            inboundItems[path+type]!.remove(at: idx)
                            Execute.background {
                                if FileManager.default.fileExists(atPath: "\(path)/\(firstfile.replacingOccurrences(of: type, with: "src"))") {
                                    try? FileManager.default.removeItem(atPath: "\(path)/\(firstfile.replacingOccurrences(of: type, with: "src"))")
                                }
                            }
                            return d
                        }
                    }
                }
            }
            
        } catch {
            
            logger.log(level: .Error, log: "Unable to open file error '\(error)'")
            return nil
            
        }
        
        return nil
        
    }
    
    
    
}
