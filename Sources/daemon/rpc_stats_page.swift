//
//  rpc_stats_page.swift
//  veldspard
//
//  Created by Adrian Herridge on 12/08/2018.
//

import Foundation
import VeldsparCore

let basePage = """
<html>
    <style>
@import 'https://fonts.googleapis.com/css?family=Open+Sans';

* {
-webkit-box-sizing: border-box;
box-sizing: border-box;
}

body {
font-family: 'Open Sans', sans-serif;
line-height: 1.75em;
font-size: 16px;
background-color: #222;
color: #aaa;
margin: 100px;
}

.simple-container {
max-width: 675px;
margin: 0 auto;
padding-top: 70px;
padding-bottom: 20px;
}

.simple-print {
fill: white;
stroke: white;
}
.simple-print svg {
height: 100%;
}

.simple-close {
color: white;
border-color: white;
}

.simple-ext-info {
border-top: 1px solid #aaa;
}

p {
font-size: 16px;
}

h1 {
font-size: 30px;
line-height: 34px;
}

h2 {
font-size: 20px;
line-height: 25px;
}

h3 {
font-size: 16px;
line-height: 27px;
padding-top: 15px;
padding-bottom: 15px;
border-bottom: 1px solid #D8D8D8;
border-top: 1px solid #D8D8D8;
}

hr {
height: 1px;
background-color: #d8d8d8;
border: none;
width: 100%;
margin: 0px;
}

a[href] {
color: #1e8ad6;
}

a[href]:hover {
color: #3ba0e6;
}

img {
max-width: 100%;
}

li {
line-height: 1.5em;
}

aside,
[class *= "sidebar"],
[id *= "sidebar"] {
max-width: 90%;
margin: 0 auto;
border: 1px solid lightgrey;
padding: 5px 15px;
}

table {
border: 3px solid #FFFFFF;
text-align: left;
border-collapse: collapse;
}
table td, table.minimalistBlack th {
border: 1px solid #FFFFFF;
padding: 5px 4px;
}
table tbody td {
font-size: 13px;
}
table thead {
background: #CFCFCF;
background: -moz-linear-gradient(top, #dbdbdb 0%, #d3d3d3 66%, #CFCFCF 100%);
background: -webkit-linear-gradient(top, #dbdbdb 0%, #d3d3d3 66%, #CFCFCF 100%);
background: linear-gradient(to bottom, #dbdbdb 0%, #d3d3d3 66%, #CFCFCF 100%);
border-bottom: 3px solid #FFFFFF;
}
table thead th {
font-size: 15px;
font-weight: bold;
text-align: left;
}
table tfoot {
font-size: 14px;
font-weight: bold;
color: #FFFFFF;
}
table tfoot td {
font-size: 14px;
}

@media (min-width: 1921px) {
body {
font-size: 18px;
}
}

</style>
    <body>
        <h1>${CURRENCY_NAME}</h1>
        <h2>Server Information</h2>
            <table>
                ${SERVER_INFORMATION}
            </table>
        <h2>Statistics</h2>
            <table>
            ${STATS}
            </table>
        <h2>Supply</h2>
            <table>
            ${SUPPLY}
            </table>
<h2>Denominations</h2>
<table>
${DENOMINATIONS}
</table>
    </body>
</html>
"""

class RPCStatsPage {
    
    class func rowWithDictionary(_ dic:[String:String]) -> String {
        
        var string = "<tr>"
        
        for o in dic {
            string += "<td>"
            string += o.key
            string += "</td>"
            string += "<td>"
            string += o.value
            string += "</td>"
        }
        
        string += "</tr>"
        return string;
        
    }
    
    class func createPage(_ stats: RPC_Stats) -> String {
        
        var page = basePage

        page = page.replacingOccurrences(of: "${CURRENCY_NAME}", with: Config.CurrencyName)
        
        // now build the server info table
        var info = rowWithDictionary(["Server name" : "\(Config.CurrencyName) Daemon"])
        info += rowWithDictionary(["Version" : Config.Version])
        
        var statistics = rowWithDictionary(["Number of tokens found" : "\(stats.number_of_tokens_found)"])
        statistics += rowWithDictionary(["Number of unique payment addresses" : "\(stats.total_unique_payment_addresses)"])
        statistics += rowWithDictionary(["Blockchain Height" : "\(stats.blockchain_height)"])
        statistics += rowWithDictionary(["Network token rate t/m" : "\(stats.token_rate)"])
        
        var supply = rowWithDictionary(["Total value of found tokens" : "\(Int(stats.total_value_of_found_tokens))"])
        supply += rowWithDictionary(["Ave token value" : "\(stats.total_value_of_found_tokens / stats.total_value_of_found_tokens)"])
        
        var denominations = ""
        for o in stats.number_of_tokens_by_denomination {
            denominations += rowWithDictionary([o.key : "\(o.value)"])
        }
        
        page = page.replacingOccurrences(of: "${SERVER_INFORMATION}", with: info)
        page = page.replacingOccurrences(of: "${DENOMINATIONS}", with: denominations)
        page = page.replacingOccurrences(of: "${STATS}", with: statistics)
        page = page.replacingOccurrences(of: "${SUPPLY}", with: supply)
        return page
        
    }
    
}
