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

class RegistrationProcessor {
    
    init() {
        
        RegistrationProcessor.processNext()
        
    }
    
    class func processNext() {
        
        Execute.background {
            
            let reg = tempManager.popRegister()
            if reg != nil {
                
                // decode this and process it
                let l = try? JSONDecoder().decode(Registration.self, from: reg!)
                
                if l != nil {
                    
                    let block = blockmaker.currentNetworkBlockHeight() + Config.TransactionMaturityLevel
                    
                    do {
                        
                        if try blockchain.registerToken(tokenString: l!.token!, address: l!.address!, block: block) {
                            logger.log(level: .Debug, log: "(Register) SUCCESSFUL token='\(l!.token!)' address='\(l!.address!)'")
                        } else {
                            logger.log(level: .Debug, log: "(Register) FAILED(exists) token='\(l!.token!)' address='\(l!.address!)'")
                        }
                        
                        RegistrationProcessor.processNext()
                        
                    } catch BlockchainErrors.TokenHasNoValue {
                        
                        RegistrationProcessor.processNext()
                        // TODO: implement banning
                        
                    } catch BlockchainErrors.InvalidToken {
                        
                        // TODO: implement banning
                        RegistrationProcessor.processNext()
                        
                    } catch {
                        RegistrationProcessor.processNext()
                    }
                    
                }
                
            } else {
                
                Execute.backgroundAfter(after: 0.5, {
                    RegistrationProcessor.processNext()
                })
                
            }
            
        }
        
    }
    
}
