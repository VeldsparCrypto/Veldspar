# SharkChain
It's called SharkChain because all my projects are SharkXXXXXXX, when forked you can call it what you like!


## Purpose:

To think about blockchain currencies differently, in this case to try to solve the issues that currently affect coin systems in production.  To use PoW & PoS to good affect.

## The concept as spewing from my head (to be refined as thoughts gather):

There are two paralell parts to the chain, 

1) the ORE to be mined, 
2) the traditional transactions block chain.

To mimic real life (resrouce based / effort based), there is ORE to mine, but this does not go away, you can mine this forever trying to find tokens.  Once found the miner can claim that token as theirs and it will be entered into the blockchain as the originating owner of that token.  The token value is based on complexity of the problem solved, so it will be easy to mine the ore to find low value tokens but take significantly longer to find larger value tokens, with an exponential curve on the effort/reward.

Because ORE can be mined forever, hash rate will be spread across the entire blockchain not just used to crack a single block.  Miners may wish to mine only a single block of ORE for many months, trying to find the highest possible value token they can, before moving onto a new one.

Tokens are defined as an address which describes the ore they were found in and a reproducable path to the discovery of the pattern.  Once the token has been found, it is submitted to the network with the miners details and an agreed timestamp (by consensus), if that miner was the first to find that token then it is written into the ledger, and that token is created and it's journey starts.

The blockchain itself is signed/sealed on a fixed time basis, so every X seconds the nominated node will validate all of the outstanding transactions, sign them and enter them into the chain.  The next node is nominated (with failovers), based on a lottery.  The entrants are all the miners who have found tokens within the last X seconds, weigted by the value of tokens found.  When nominated, they get to validate the next block, and if it is due, they also create the next ORE block as well.

## Benefits?

*  Distributed
*  Blockchain itself is just transactions, so small and fast to syncronise
*  ORE system, means hashrate is distributed across entire chain, therefore stopping anyone smashing the network with nicehash/asic rigs.
*  No fixed reward and no fixed supply.   Only a likelyhood of reward/total supply, based on the amount of effort used to mine the ore.  This stops early adopters from getting anythign more than late adopters, because they are not rewarded for being first other than the low value easy tokens.
*  ORE does not need to be stored on all nodes, but transactions will.  This will allow for space limited installations of nodes.

## Downsides?

* Low value tokens may be found too fast and there may be a significant chance of a miners "find" having been claimed already.  Therefore miners may avoid low value tokens, making it difficault to send tokens to other addresses.
* As above, tokens mimic real word money, in that you can have T0.01, T0.20 & T1.00, but you could not send T0.30 to someone as you do not have the denomination to do so.  The network would have to try to distribute large and small tokens to make sure there was always enough "change" to have transactions succeed.

## Tokens?

Tokens are described as the positional information of their location within the ore, the method used to generate it, and the value signature.

And example would be:

<ore sig><input 1 offset><input 2 offset><input 3 offset><input 4 offset><method><algo><value>
  
### Methods:

This would be an ennumeration of 0-255 styles of operation, for example 0 might be append, 1 might be prepend, 2 might be split & insert etc...  Becoming ever more CPU intensive to derrive more value from the find.

The tokens should be hard to find, but very fast to validate, as the nodes will be required to validate all the finds so they can be incorporated into the ledger at a point in the future.
  
## Economy

This is tricky, as it mimics real world resource availability and therefore there are no fixed emmissions of tokens, it is purely what is found in the ore provided, which is of course entirely random.

## Network issues

One of the major pain points is going to be the claiming of low value tokens, as a powerful machine may be able to find many hundreds of the smallest denominations per second, and there will be a "gold rush" as to who those tokens were allocated too.  With many miners finding the same tokens.
