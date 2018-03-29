# SharkChain
It's called SharkChain because all my projects are SharkXXXXXXX, when forked you can call it what you like!


##Purpose:

To think about blockchain currencies differently, in this case to try to solve the issues that currently affect coin systems in production.  To use PoW & PoS to good affect.

##The concept as spewing from my head (to be refined as thoughts gather):

There are two paralell parts to the chain, 1) the ORE, 2) the tradition transactions chain.

To mimic real life (resrouce based / effort based), there is ORE to mine, but this does not go away, you can mine this forever trying to find tokens.  Once found the miner can claim that token as theirs and it will be entered into the blockchain as the originating owner of that token.  The token value is based on complexity of the problem solved, so it will be easy to mine the ore to find low value tokens but take significantly longer to find larger value tokens, with an exponential curve on the effort/reward.

Because ORE can be mined forever, hash rate will be spread across the entire blockchain not just used to crack a single block.  Miners may wish to mine only a single block of ORE for many months, trying to find the highest possible value token they can, before moving onto a new one.

Tokens are defined as an address which describes the ore they were found in and a reproducable path to the discovery of the pattern.  Once the token has been found, it is submitted to the network with the miners details and an agreed timestamp (by consensus), if that miner was the first to find that token then it is written into the ledger, and that token is created and it's journey starts.

The blockchain itself is signed/sealed on a fixed time basis, so every X seconds the nominated node will validate all of the outstanding transactions, sign them and enter them into the chain.  The next node is nominated (with failovers), based on a lottery.  The entrants are all the miners who have found tokens within the last X seconds, weigted by the value of tokens found.  When nominated, they get to validate the next block, and if it is due, they also create the next ORE block as well.

##Benefits?

*  Distributed
*  Blockchain itself is just transactions, so small and fast to syncronise
*  ORE system, means hashrate is distributed across entire chain, therefore stopping anyone smashing the network with nicehash/asic rigs.
*  No fixed reward and no fixed supply.   Only a likelyhood of reward/total supply, based on the amount of effort used to mine the ore.  This stops early adopters from getting anythign more than late adopters, because they are not rewarded for being first other than the low value easy tokens.
*  ORE does not need to be stored on all nodes, but transactions will.  This will allow for space limited installations of nodes.
