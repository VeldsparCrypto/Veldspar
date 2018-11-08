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

class Settings : Codable {
    
    var node_id: String = UUID().uuidString.CryptoHash()
    var blockchain_export_data: Bool = false
    var blockchain_export_data_path: String = "./cache/blocks"
    var blockchain_produce_blocks: Bool = false
    var network_distribute_transactions: Bool = false
    var network_accept_transactions: Bool = true
    var network_accept_registrations: Bool = false
    var network_port: Int = 14242
    var rpc_allow_block: Bool = true
    var rpc_allow_height: Bool = true
    var rpc_allow_timestamp: Bool = true
    var rpc_allow_pending: Bool = true
    var rpc_allow_transfer: Bool = false
    var rpc_ban_invalid_requests: Bool = true
    var rpc_ban_invalid_limit: Int = 10
    var database_service_type: String = "SQLITE"
    var database_cache_size: Int = 8
    var database_connection_string: String? = nil
    var database_connection_username: String? = nil
    var database_connection_password: String? = nil
    var debug_mirror_requests: Bool? = false
    var debug_mirror_target: String? = nil
    
}
