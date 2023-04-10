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
$ truffle test --network polygon_fork 
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
- After Mumbai deployment deploy the client part on Vercel or another Cloud provider

