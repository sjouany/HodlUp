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