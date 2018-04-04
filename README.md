# SharkChain
It's called SharkChain because all my projects are SharkXXXXXXX, when forked you can call it what you like!


## Purpose:

To think about block chain currencies differently, in this case to try to solve the issues that currently affect coin systems in production.  To use PoW & PoS to good affect.

## The concept as spewing from my head (to be refined as thoughts gather):

There are two parallel parts to the chain, 

1) the ORE to be mined, 
2) the traditional transactions block chain.

To mimic real life (resource based / effort based), there is ORE to mine, but this does not go away, you can mine this forever trying to find tokens.  Once found the miner can claim that token as theirs and it will be entered into the block chain as the originating owner of that token.  The token value is based on complexity of the problem solved, so it will be easy to mine the ore to find low value tokens but take significantly longer to find larger value tokens, with an exponential curve on the effort/reward.

Because ORE can be mined forever, hash rate will be spread across the entire block chain not just used to crack a single block.  Miners may wish to mine only a single block of ORE for many months, trying to find the highest possible value token they can, before moving onto a new one.

Tokens are defined as an address which describes the ore they were found in and a reproducible path to the discovery of the pattern.  Once the token has been found, it is submitted to the network with the miners’ details and an agreed timestamp (by consensus), if that miner was the first to find that token then it is written into the ledger, and that token is created, and its journey starts.

The block chain itself is signed/sealed on a fixed time basis, so every X seconds the nominated node will validate all of the outstanding transactions, sign them and enter them into the chain.  The next node is nominated (with failovers), based on a lottery.  The entrants are all the miners who have found tokens within the last X seconds, weighted by the value of tokens found.  When nominated, they get to validate the next block, and if it is due, they also create the next ORE block as well.

## Benefits?

*  Distributed
*  Block chain itself is just transactions, so small and fast to synchronise
*  ORE system, means hash rate is distributed across entire chain, therefore stopping anyone smashing the network with nicehash/asic rigs.
*  No fixed reward and no fixed supply.   Only a likelihood of reward/total supply, based on the amount of effort used to mine the ore.  This stops early adopters from getting anything more than late adopters, because they are not rewarded for being first other than the low value easy tokens.
*  ORE does not need to be stored on all nodes, but transactions will.  This will allow for space limited installations of nodes.

## Downsides?

* Low value tokens may be found too fast and there may be a significant chance of a miners "find" having been claimed already.  Therefore, miners may avoid low value tokens, making it difficult to send tokens to other addresses.
* As above, tokens mimic real word money, in that you can have T0.01, T0.20 & T1.00, but you could not send T0.30 to someone as you do not have the denomination to do so.  The network would have to try to distribute large and small tokens to make sure there was always enough "change" to have transactions succeed.

## Tokens?

Tokens are described as the positional information of their location within the ore, the method used to generate it, and the value signature.

And example would be:

`<height><method><algorithm><value><add1>..<add n>`

Which looks like for a 64bit token with 8 paths:

`00000001-00-00-00000001-00046411-00005839-0002C3CD-000B5BA9-00010B6F-00002AEA-0007E24D-000EC5F6`
  
  
### Methods:

This would be an enumeration of 0-255 styles of operation, for example 0 might be append, 1 might be prepend, 2 might be split & insert etc...  Becoming ever more CPU intensive to derive more value from the find.

### Algorithm 

This would be appropriate hashing algo’s or indeed anything else that the token considers appropriate to use to provide an appropriate level of PoW.

The tokens should be hard to find, but very fast to validate, as the nodes will be required to validate all the finds, so they can be incorporated into the ledger at a point in the future.
  
## Economy

This is tricky, as it mimics real world resource availability and therefore there are no fixed emissions of tokens, it is purely what is found in the ore provided, which is of course entirely random.

## Network issues

One of the major pain points is going to be the claiming of low value tokens, as a powerful machine may be able to find many hundreds of the smallest denominations per second, and there will be a "gold rush" as to who those tokens were allocated too.  With many miners finding the same tokens.

## Fairness

As it is impossible (or at least not-likely) for developers to pre-mine the token, other than "knowing" about the coin first there is no fixed pay-out, only a reward for effort applied so this should reduce the amount of bag holding that early adopters have traditionally amassed.

Sequential mining is discouraged as you will be likely to find blocks which have already been claimed, therefore, randomised mining of the ore would yield the best possible return for effort.

## Mining

So mining, consists of finding tokens within the ore.  By default, a block of ore is 1mb of data.  The miner has to try 8 x 64 byte sections of that ore, using one of 2 initial methods (prepend & append), then one of 4 hash algorithms will be used to try to find a valid token.  This gives possibilities to try of approximately 1.19^58 combinations.  But with there being up to 256 methods and 256 algos.  Ore blocks follow a different release schedule, so may well be every 10k blocks, or 100k.

## Transparency

This is a tricky one for me to really wrap my head around, personally I love the idea of entirely anonymous currencies free from the outside snooping on what you have.  But in a fair and balanced society, everyone should be held to account for what they hold.  As only when something is free and open can trust be established.  Also, if you are looking to create a crypto currency that is welcomed with open arms by payment providers and governments, a certain amount of auditing must be possible whist still allowing some anonymity. 

This will be a tricky problem to solve as you wish to balance the two, and ensure you are protecting both sides but still allowing the network to be entirely independent and beyond the control of any single individual or agency.

