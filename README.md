# Veldspar - Cryptocurrency

## Purpose:

* To think about block chain currencies differently (in this case to try to solve the issues that currently affect coin systems in production).  
* To use PoW & PoS to good affect.  The PoS actually being the amount in hash power you apply to the network giving you a proportionate return. 

## The concept:

There are two parallel parts to the chain; 

1) the ORE to be mined, 
2) the traditional transactions block chain secured through consensus and not mining.

To mimic real life (resource based / effort based), there is ORE to mine, but this does not go away or timeout. You can mine this forever trying to find tokens.  Once found the miner can claim that token as theirs and it will be entered into the block chain as the originating owner of that token.  The token value is random, based on which of the "magic values" were found within the hash, this is to allow for tokens to be found at various denominations, with the lower values being more numerous to create a more relaistic supply.

Because the ORE can be imed independently and randomly, hash power has no effect on the blockchain and it is not possible for larger miners to "swoop in" and take anything from miners who are say just using a laptop at home.

Tokens are defined as addresses describing the position within the ore they were found in, and a reproducible path to the discovery of the pattern.  Once a token has been found, it is submitted to the network with the miners’ details and an agreed timestamp (by consensus). If that miner was the first to find that token then it is written into the ledger, and that token is created, and its journey starts.

The block chain itself is signed/sealed on a fixed time basis, so every X seconds the  all of the outstanding transactions in arrears will be selected, signed and entered into the chain.  Once this has been done, the hash for the block is distributed to all connected nodes, and the originating nodes will receive other nodes' hashes.  Then quorum is established.  If the hash you supply is outvoted by a significant proportion of the other nodes, then that block is not written to the local store, and instead a copy of the transactions is gained from several sources, compared, and the process is run again.

## Benefits?

*  Distributed
*  Block chain itself is just transactions, so small and fast to synchronise
*  ORE system, means hash rate is distributed across entire chain, therefore stopping anyone smashing the network with nicehash/asic rigs.
*  No fixed reward and no fixed supply.   Only a likelihood of reward/total supply, based on the amount of effort used to mine the ore.  This stops early adopters from getting anything more than late adopters, because they are not rewarded for being first other than the low value easy tokens.
*  ORE does not need to be stored on all nodes, but transactions will.  This will allow for space limited installations of nodes.
*  You are not fighting other miners, your effort is directly rewarded with wealth.  People who apply more hash-rate get proportionally more reward.

## Downsides?

* Low value tokens will be extremely numerous, so sending large transaction may have many 1000's of tokens within it.
* As above, tokens mimic real word money, in that you can have T0.01, T0.20 & T1.00, but you could not send T0.30 to someone as you do not have the denomination to do so.  The network would have to try to distribute large and small tokens to make sure there was always enough "change" to have transactions succeed.

## Tokens?

Tokens are described as the positional information of their location within the ore, the method used to generate it, and the value signature.

And example would be:

`<ore>-<algorithm>-<value>-<address>`

Which looks, for a 64bit token with 8 paths, like:

`01-01-01-00046411000058390002C3CD`
  
  
### Methods:

This would be an enumeration of 0-255 styles of operation, for example 0 might be append, 1 might be prepend, 2 might be split & insert etc...  Becoming ever more CPU intensive to derive more value from the find.

### Algorithm 

This would be appropriate hashing algo’s or indeed anything else that the token considers appropriate to use to provide an appropriate level of PoW.

The tokens should be hard to find, but very fast to validate, as the nodes will be required to validate all the finds, so they can be incorporated into the ledger at a point in the future.
  
## Economy

This is tricky, as it mimics real world resource availability and therefore there are no fixed emissions of tokens, it is purely what is found in the ore provided, which is of course entirely random.

## Network issues

One of the major pain points is going to be the claiming of low value tokens, as a powerful machine may be able to find many hundreds of the smallest denominations per second, and there will be a "gold rush" as to who those tokens were allocated to, with many miners finding the same tokens. This will be helped in the main by the miners applying random mining techniques.

## Fairness

As it is impossible (or at least not-likely) for developers to pre-mine the token, other than "knowing" about the coin first, there is no fixed pay-out, only a reward for effort applied so this should reduce the amount of bag holding that early adopters have traditionally amassed.

Sequential mining is discouraged as you will be likely to find blocks which have already been claimed, therefore, randomised mining of the ore would yield the best possible return for effort.

## Mining

So mining, consists of finding tokens within the ore.  By default, a block of ore is 1mb of data.  The miner has to try 8 x 64 byte sections of that ore, using one of 2 initial methods (prepend & append), then one of 4 hash algorithms will be used to try to find a valid token.  This gives possibilities to try of approximately 1.19^58 combinations.  But with there being up to 256 methods and 256 algos.  Ore blocks follow a different release schedule, so may well be every 10k blocks, or 100k.

## Transparency

This is a tricky one for me to really wrap my head around, personally I love the idea of entirely anonymous currencies free from the outside snooping on what you have.  But in a fair and balanced society, everyone should be held to account for what they hold.  As only when something is free and open can trust be established.  Also, if you are looking to create a crypto currency that is welcomed with open arms by payment providers and governments, a certain amount of auditing must be possible whist still allowing some anonymity. 

This will be a tricky problem to solve as you wish to balance the two, and ensure you are protecting both sides but still allowing the network to be entirely independent and beyond the control of any single individual or agency.

## Method

There will be three data structures underlying the chain.

1) The blockchain itself, containing `<Blocks>`, tied together with SHA512 hash of all it's transactions + previous block hash
2) Transactions, containing the from -> to, date, ref & tokens to be reallocated
3) Ledger, the in/out record for all tokens in the chain.  Ownership can be established by looking at the last allocation of a token, and tested before spending that token.  Also, registration of a token can be tested by the non-existence of an existing allocation for that token.
  
Because there will be no proof of work for the blockchain, we must secure it via consensus.  With the seed nodes being authoritative whilst the network size is insufficient or quorum cannot be achieved.

Consensus is based (due to timing anomalies) on transactions being submitted to the network with a target block membership, which is far enough in the future to ensure it’s distribution around the network in sufficient time (say at least 1 min).  Then when the next block is due to be produced the nodes will gather the outstanding transactions for the block, order the transactions by their identifier and hash them, then hash that result against the previous block.

The node will then send this final hash around to other nodes to gain consensus, each node will record the number of hits/misses of that hash it receives and write that into the blockchain as a record of the network quorum for that block. In the case where there is significant disagreement, then the seed nodes become authoritative, although this should never happen or be inconsequentially irregular as to not be a problem.  

In the case where a node becomes outnumbered in it’s resolution of a block, it will not commit that block into the store, and will instead ask another node (likely a seed node) for all it’s transactions for a block, then re-process that block and check the hash now matches the consensus and if it passes then write the block into the datastore.

# Roadmap:
* v0.1.x - Initial seed node created, mining active, wallets created, no replication to other nodes.
* v0.2.x - Live replication, p2p to other nodes, Seed nodes authoritive on token registration and spends
* v0.3.x - Quorum introduced, seed nodes no longer authoritive unless 50/50 decision requires adjudication.
* v0.4.x - Introduce ledger compaction, only allocation and previous allocation required to be kept past a certain point.

# Installation:

## Currently these instructions are for Ubuntu 18.04 only:

### Pre-requisits

The following modules:
clang,libicu-dev,sqlite3,libsqlite3-dev

```
#linux-swift-install
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get install clang libicu-dev sqlite3 libsqlite3-dev uuid-dev
```

Swift 5.0.0 from swift.org.
https://swift.org/builds/swift-5.0-release/ubuntu1804/swift-5.0-RELEASE/swift-5.0-RELEASE-ubuntu18.04.tar.gz

The following script downloads Swift and jams it into /usr (not pretty, but effective).  Best done on a sandbox VM.  

PERFORM AS SU/ROOT
```
cd ~/
wget https://swift.org/builds/swift-5.0-release/ubuntu1804/swift-5.0-RELEASE/swift-5.0-RELEASE-ubuntu18.04.tar.gz
tar -xvf swift-5.0-RELEASE-ubuntu18.04.tar.gz
cd swift-5.0-RELEASE-ubuntu18.04
sudo cp -R usr/* /usr
cd ~/
rm -rf swift-5.0-RELEASE-ubuntu18.04
rm swift-5.0-RELEASE-ubuntu18.04.tar.gz
```

PERFORM AS NORMAL USER
Clone Veldspar, build it, and copy it into the ~/.Veldspar directory.
```
cd ~/
git clone https://github.com/VeldsparCrypto/Veldspar.git
cd Veldspar

swift build -c release
mkdir ~/.Veldspar

cd .build
cd release

cp veldspard ~/.Veldspar/veldspard
cp miner ~/.Veldspar/miner
cp simplewallet ~/.Veldspar/simplewallet

```


