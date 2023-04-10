# HodlUp
Decentralized DCA web3 Dapp

deploy Mumbai (from truffle folder):
truffle migrate --reset --network mumbai --f 02

deploy dev fork mainnet (from truffle folder):
truffle migrate --network polygon_fork --to 01

To run tests (from truffle folder)
truffle test --network polygon_fork 

for dev some tools to provide token to the wallet and initialize values for the smart contract
cd scripts/demo_local_fork; node init_demo

to run the front for dev:
npm run dev

Ganache commandline to work with polygon mainnet fork:
ganache -f https://polygon-mainnet.g.alchemy.com/v2/E_47dJ_8PBLE24COiPQ1hcE1ZIBVgcps -u 0xe7804c37c13166fF0b37F5aE0BB07A3aEbb6e245 --networkId 137 -m "set the mnemonic for your account"