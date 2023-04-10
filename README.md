# HodlUp

HodlUp is a Decentralized DCA web3 Dapp

## Links
- You can see the video here : **https://youtu.be/WgnW4xoq28k**
- Dapp deployed on Vercel : **https://vercel.com/sjouany/hodl-up**


## Installation

- Clone gitHub repository
- Install dependencies on **truffle** folder and **client** folder

```sh
$ npm install
```

## Launch unit tests:

- Prérequisite : launch ganache with a polygon fork
- Replace  ***ALCHEMY_ID*** by your own alchemy ID and set your ***mnemonic***

```sh
$ ganache -f https://polygon-mainnet.g.alchemy.com/v2/ALCHEMY_ID -u 0xe7804c37c13166fF0b37F5aE0BB07A3aEbb6e245 --networkId 137 -m "put your wallet mnemonic here"
```

- from truffle launch **truffle test** (don't forget before to update informations inside truffle-config.js) 

```sh
$ truffle test --network polygon_fork --to 01
```

- Test report 
```sh
> Compiled successfully using:
   - solc: 0.8.18+commit.87f61d96.Emscripten.clang

  Contract: Hodl
    test constructor
      ✓ should be initialize contract states (1130ms, 801077 gas)
    test mint
      ✓ should not mint (not owner) (1211ms, 801077 gas)
      ✓ should mint (1192ms, 871925 gas)

  Contract: HodlUpHub
    test constructor
      ✓ should be initialize contract states (1203ms, 6071434 gas)
    test Pair creation
      ✓ should not create Pair (not owner) (24ms)
      ✓ should not create Pair (must be different) (22ms)
      ✓ should not create Pair (Non existing Input Token) (407ms)
      ✓ should not create Pair (Non existing Output Token) (30ms)
      ✓ should create Pair (event) (614ms, 109111 gas)
      ✓ should create Pair (573ms, 109111 gas)
      ✓ should not create Pair (already exists) (724ms, 109111 gas)
    test Interval creation
      ✓ should not create Interval (not owner) (30ms)
      ✓ should create Interval (351ms, 69447 gas)
      ✓ should create Interval (event) (421ms, 69447 gas)
    test Position Creation
      ✓ should not create Position (name empty) (41ms)
      ✓ should not create Position (pair not available) (193ms)
      ✓ should not create Position (interval not available) (181ms)
      ✓ should not create Position (no amount for DCA) (169ms)
      ✓ should not create Position (amount per swap and number of iterations) (185ms)
      ✓ should create Position (without stacking and number iteration set) (3466ms, 389954 gas)
      ✓ should create Position (without stacking and amount per swap set) (3746ms, 369847 gas)
      ✓ should create Position (with stacking) (3763ms, 389966 gas)
      ✓ should create Position (event) (4698ms, 389954 gas)
      ✓ should not create Position (already exists) (4141ms, 389954 gas)
      ✓ should create Position (test adding user into users Addresses array) (4274ms, 389954 gas)
      ✓ should not set Position Status(Position doesn't exist) (3948ms, 389954 gas)
    test DCA
      ✓ should execute swap without stacking (10197ms, 664240 gas)
      ✓ should execute swap without stacking (event) (6414ms, 647140 gas)
      ✓ should execute swap without stacking and with no sufficient funds (9407ms, 962481 gas)
      ✓ should execute swap with stacking (5047ms, 655737 gas)
      ✓ should execute swap with stacking (event) (5964ms, 655737 gas)
    Close Position
      ✓ should not close position (does'nt exist) (43ms)
      ✓ should not close position (position locked) (80ms, 31405 gas)

  Contract: HodlUpRewardsManager
    test constructor
      ✓ should be initialize contract states (160ms, 1759312 gas)
    test setter
      ✓ should not set APY (Only Owner) (2ms)
      ✓ should set APY (48ms, 28660 gas)
      ✓ should not set Reward Token (Only Owner) (1ms)
      ✓ should set Reward Token (46ms, 28984 gas)
      ✓ should not add Oracle (Only Owner) (1ms)
      ✓ should add Oracle (178ms, 46618 gas)
      ✓ should not add Contract (2ms)
      ✓ should add Contract (0ms)
      ✓ should add Contract (event) (1ms)
    test reward management
      ✓ should get the USD price for SAND (1852ms)

·----------------------------------------------|---------------------------|-------------|----------------------------·
|     Solc version: 0.8.18+commit.87f61d96     ·  Optimizer enabled: true  ·  Runs: 200  ·  Block limit: 6718946 gas  │
···············································|···························|·············|·····························
|  Methods                                     ·               1 gwei/gas                ·       1.02 eur/matic       │
·························|·····················|·············|·············|·············|··············|··············
|  Contract              ·  Method             ·  Min        ·  Max        ·  Avg        ·  # calls     ·  eur (avg)  │
·························|·····················|·············|·············|·············|··············|··············
|  Hodl                  ·  approve            ·      28602  ·      58134  ·      44445  ·          43  ·       0.00  │
·························|·····················|·············|·············|·············|··············|··············
|  Hodl                  ·  mint               ·      70848  ·      70932  ·      70890  ·           2  ·       0.00  │
·························|·····················|·············|·············|·············|··············|··············
|  Hodl                  ·  transfer           ·      40804  ·      58776  ·      41750  ·          19  ·       0.00  │
·························|·····················|·············|·············|·············|··············|··············
|  HodlUpHub             ·  addInterval        ·          -  ·          -  ·      69447  ·          23  ·       0.00  │
·························|·····················|·············|·············|·············|··············|··············
|  HodlUpHub             ·  addPair            ·          -  ·          -  ·     109111  ·          28  ·       0.00  │
·························|·····················|·············|·············|·············|··············|··············
|  HodlUpHub             ·  createPosition     ·     369847  ·     389966  ·     387086  ·          21  ·       0.00  │
·························|·····················|·············|·············|·············|··············|··············
|  HodlUpHub             ·  executeSwap        ·     119832  ·     274286  ·     242386  ·          15  ·       0.00  │
·························|·····················|·············|·············|·············|··············|··············
|  HodlUpHub             ·  setPositionStatus  ·          -  ·          -  ·      31405  ·           1  ·       0.00  │
·························|·····················|·············|·············|·············|··············|··············
|  HodlUpRewardsManager  ·  addContract        ·          -  ·          -  ·      47206  ·           1  ·       0.00  │
·························|·····················|·············|·············|·············|··············|··············
|  HodlUpRewardsManager  ·  addOracle          ·          -  ·          -  ·      46618  ·           3  ·       0.00  │
·························|·····················|·············|·············|·············|··············|··············
|  HodlUpRewardsManager  ·  setApy             ·          -  ·          -  ·      28660  ·           2  ·       0.00  │
·························|·····················|·············|·············|·············|··············|··············
|  HodlUpRewardsManager  ·  setRewardToken     ·          -  ·          -  ·      28984  ·           2  ·       0.00  │
·························|·····················|·············|·············|·············|··············|··············
|  Deployments                                 ·                                         ·  % of limit  ·             │
···············································|·············|·············|·············|··············|··············
|  Hodl                                        ·          -  ·          -  ·     801077  ·      11.9 %  ·       0.00  │
···············································|·············|·············|·············|··············|··············
|  HodlUpHub                                   ·          -  ·          -  ·    4312122  ·      64.2 %  ·       0.00  │
···············································|·············|·············|·············|··············|··············
|  HodlUpRewardsManager                        ·          -  ·          -  ·     958235  ·      14.3 %  ·       0.00  │
·----------------------------------------------|-------------|-------------|-------------|--------------|-------------·

  44 passing (4m)
```

## Local Deployment and execution

- Same prerequisite than previous chapter for unit tests : you have to launch **ganache** with polygon fork
```sh
$ ganache -f https://polygon-mainnet.g.alchemy.com/v2/ALCHEMY_ID -u 0xe7804c37c13166fF0b37F5aE0BB07A3aEbb6e245 --networkId 137 -m "put your wallet mnemonic here"
```

- from **truffle** folder:

```sh
$ truffle migrate --network polygon_fork --to 01
```
- To provide tokens to the wallet and initialize values for the smart contract s

```sh
// update 'myAddress' on init_demo.js
$ cd scripts/demo_local_fork; node init_demo
```
- from **client** folder:
```sh
$ npm run dev
```
- Dapp is now available here: **http://localhost:3000/**

-if you want to simulate a swap you can execute following command from **truffle** folder
```sh
$ cd scripts/demo_local_fork; node launch_dca_exec
```

## Mumbai Testnet Deployment and execution

- from **truffle** folder:

```sh
$ truffle migrate --reset --network mumbai --f 02
```

```sh
Compiling your contracts...
===========================
> Everything is up to date, there is nothing to compile.


Starting migrations...
======================
> Network name:    'mumbai'
> Network id:      80001
> Block gas limit: 20196158 (0x1342b3e)


02_deploy_mumbai.js
===================

   Replacing 'Hodl'
   ----------------
   > transaction hash:    0xb56d8cd88bcbea04fc07a0bd7720cd9eedb3c10efe9a8633515ec897ec793dcf
   > Blocks: 2            Seconds: 4
   > contract address:    0x457E049E1bA52A07F6d0540cCBb5EC3c912438a0
   > block number:        34211772
   > block timestamp:     1681154733
   > account:             0x2dC55ec5fC4a5D2dDd662f747F3a4f1784F34eEC
   > balance:             5.203944054085658372
   > gas used:            801077 (0xc3935)
   > gas price:           2.500000016 gwei
   > value sent:          0 ETH
   > total cost:          0.002002692512817232 ETH


   Replacing 'HodlUpRewardsManager'
   --------------------------------
   > transaction hash:    0x8384fde62e07fd78ccec9864e1332f714b67eb4c00b1596a11fea450c34a0cec
   > Blocks: 3            Seconds: 8
   > contract address:    0x4849FaeC608A0E1008b7d230671747E6aa7eA238
   > block number:        34211776
   > block timestamp:     1681154743
   > account:             0x2dC55ec5fC4a5D2dDd662f747F3a4f1784F34eEC
   > balance:             5.201548466570326612
   > gas used:            958235 (0xe9f1b)
   > gas price:           2.500000016 gwei
   > value sent:          0 ETH
   > total cost:          0.00239558751533176 ETH


   Replacing 'HodlUpHub'
   ---------------------
   > transaction hash:    0xd2666e1b1dd7b0fb67b648de230aa558701dde5b8b35c09d493dc1f05a9ed981
   > Blocks: 2            Seconds: 4
   > contract address:    0xd7583471402Fb9094c4bde70BF4A3ddc03A49a35
   > block number:        34211780
   > block timestamp:     1681154751
   > account:             0x2dC55ec5fC4a5D2dDd662f747F3a4f1784F34eEC
   > balance:             5.19076816150133266
   > gas used:            4312122 (0x41cc3a)
   > gas price:           2.500000016 gwei
   > value sent:          0 ETH
   > total cost:          0.010780305068993952 ETH
```

- After Mumbai deployment deploy the client part on Vercel or another Cloud provider