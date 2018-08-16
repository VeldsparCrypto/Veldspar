//
//  rpc_stats_page.swift
//  veldspard
//
//  Created by Adrian Herridge on 12/08/2018.
//

import Foundation
import VeldsparCore

let graph = """
<canvas id="$ID" width="800" height="400"></canvas>
<script>
var ctx = document.getElementById("$ID").getContext('2d');
var myChart = new Chart(ctx, {
type: 'line',
data: {
labels: $LABELS,
datasets: [{
label: "Data",
borderColor: "#80b6f4",
pointBorderColor: "#80b6f4",
pointBackgroundColor: "#80b6f4",
pointHoverBackgroundColor: "#80b6f4",
pointHoverBorderColor: "#80b6f4",
pointBorderWidth: 2,
pointHoverRadius: 2,
pointHoverBorderWidth: 2,
pointRadius: 2,
fill: false,
borderWidth: 2,
data: $DATA
}]
},
options: {
responsive: false,
title: {
display: true,
text: '$TITLE'
},
tooltips: {
mode: 'index',
intersect: false,
},
hover: {
mode: 'nearest',
intersect: true
},
scales: {
xAxes: [{
display: true,
scaleLabel: {
display: true,
labelString: '$BOTTOMTITLE'
}
}],
yAxes: [{
display: true,
scaleLabel: {
display: true,
labelString: '$SIDETITLE'
}
}]
}
}
});
</script>
"""

func Chart(title: String, bottomAxis: String, sideAxis: String, data: [(String, Double)]) -> String {
   
    var c = graph
    c = c.replacingOccurrences(of: "$TITLE", with: title)
    c = c.replacingOccurrences(of: "$ID", with: title.sha224())
    c = c.replacingOccurrences(of: "$SIDETITLE", with: sideAxis)
    c = c.replacingOccurrences(of: "$BOTTOMTITLE", with: bottomAxis)
    
    // build two arrays of data
    var titlesArray: [String] = []
    var dataArray: [Double] = []
    for o in data {
        titlesArray.append(o.0)
        dataArray.append(o.1)
    }
    
    c = c.replacingOccurrences(of: "$LABELS", with: "\(titlesArray)")
    c = c.replacingOccurrences(of: "$DATA", with: "\(dataArray)")
    
    return c
    
}

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
<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.7.2/Chart.bundle.js"></script>

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

${EMISSION_CHART}

${VALUE_CHART}

${DEPLETION_CHART}

${USERS_CHART}

${ACTIVE_CHART}

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
        
        var statistics = rowWithDictionary(["Number of tokens found" : "\(stats.tokens)"])
        statistics += rowWithDictionary(["Number of unique payment addresses" : "\(stats.addresses)"])
        statistics += rowWithDictionary(["Blockchain Height" : "\(stats.height)"])
        statistics += rowWithDictionary(["Network token rate t/m" : "\(stats.rate)"])
        
        var supply = rowWithDictionary(["Total value of found tokens" : "\(Int(stats.value))"])
        supply += rowWithDictionary(["Ave token value" : "\(stats.value / stats.tokens)"])
        
        var denominations = ""
        for o in stats.denominations {
            denominations += rowWithDictionary([o.key : "\(o.value)"])
        }
        
        page = page.replacingOccurrences(of: "${SERVER_INFORMATION}", with: info)
        page = page.replacingOccurrences(of: "${DENOMINATIONS}", with: denominations)
        page = page.replacingOccurrences(of: "${STATS}", with: statistics)
        page = page.replacingOccurrences(of: "${SUPPLY}", with: supply)
        

        // emmission data
        var emissionData: [(String, Double)] = []
        for b in stats.blocks {
            if b.height > 10 {
            emissionData.append(("\(b.height)",Double(b.newTokens)))
            }
        }
        
        page = page.replacingOccurrences(of: "${EMISSION_CHART}", with: Chart(title: "Token Emission", bottomAxis: "Block No", sideAxis: "Number of Tokens", data: emissionData))
        
        // value data
        var valueData: [(String, Double)] = []
        for b in stats.blocks {
            if b.height > 10 {
                valueData.append(("\(b.height)",Double((b.newValue / Config.DenominationDivider))))
            }
        }
        
        page = page.replacingOccurrences(of: "${VALUE_CHART}", with: Chart(title: "Value Emission", bottomAxis: "Block No", sideAxis: "Value of Tokens", data: valueData))
        
        // depletion data
        var depletionData: [(String, Double)] = []
        for b in stats.blocks {
            if b.height > 3400 {
                depletionData.append(("\(b.height)", b.depletion))
            }
        }
        
        page = page.replacingOccurrences(of: "${DEPLETION_CHART}", with: Chart(title: "Depletion", bottomAxis: "Block No", sideAxis: "Depletion rate", data: depletionData))
        
        // address data
        var addressData: [(String, Double)] = []
        for b in stats.blocks {
            if b.height > 10 {
                addressData.append(("\(b.height)", Double(b.addressHeight)))
            }
        }
        
        page = page.replacingOccurrences(of: "${USERS_CHART}", with: Chart(title: "Users", bottomAxis: "Block No", sideAxis: "Addresses", data: addressData))
        
        // active data
        var activeData: [(String, Double)] = []
        for b in stats.blocks {
            if b.height > 10 {
                activeData.append(("\(b.height)", Double(b.activeAddresses)))
            }
        }
        
        page = page.replacingOccurrences(of: "${ACTIVE_CHART}", with: Chart(title: "Active Users", bottomAxis: "Block No", sideAxis: "Addresses", data: activeData))
        
        return page
        
    }
    
}
