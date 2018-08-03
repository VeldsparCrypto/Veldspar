//
//  rpc_get_block.swift
//  veldspard
//
//  Created by Adrian Herridge on 03/08/2018.
//

import Foundation
import VeldsparCore

class RPCGetBlock {
    
    class func action(_ height: Int) -> RPC_Block {
        
        let rpcBlock = RPC_Block()
        
        let b = blockchain.blockAtHeight(UInt32(height))
        if b != nil {
            
            rpcBlock.hash = b?.hash
            rpcBlock.height = b?.height
            rpcBlock.seed = b?.oreSeed
            
            for l in b?.transactions ?? [] {
                
                let ledger = RPC_Ledger()
                ledger.block = l.block
                ledger.date = l.date
                ledger.destination = l.destination
                ledger.op = l.op.rawValue
                ledger.spend_auth = l.spend_auth
                ledger.token = l.token
                ledger.transaction_group = l.transaction_group
                ledger.transaction_id = l.transaction_id

                rpcBlock.transactions.append(ledger)
                
            }
            
        }
        
        return rpcBlock
        
    }
    
}
