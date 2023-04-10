
require('dotenv').config();
const Web3 = require("web3")
const HDWalletProvider = require('@truffle/hdwallet-provider');

const provider =  new HDWalletProvider(`${process.env.MNEMONIC}`, `https://polygon-mumbai.g.alchemy.com/v2/${process.env.ALCHEMY_ID}`);
const web3 = new Web3(provider)

const contractABIQ = require("../../../client/src/contracts/HodlUpHub.json")

const contract = new web3.eth.Contract(contractABIQ.abi, contractABIQ.networks[137].address)
const myAddress = "0x2dC55ec5fC4a5D2dDd662f747F3a4f1784F34eEC"

async function main() {
  try {
    await contract.methods.executeSwap().send({ from: myAddress, gas: '500000' })  
  } catch (err) {
    console.log("An error occurred", err)
  }
}

main()










