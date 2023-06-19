
const Web3 = require("web3")
const web3 = new Web3("http://localhost:8545")

const contractABIQ = require("../../../client/src/contracts/HodlUpHub.json")

const contractAddress = "0x1670A50E15a4d350fF093482614B9E82BF0B3D69"
const contract = new web3.eth.Contract(contractABIQ.abi, contractABIQ.networks[137].address)
const myAddress = "0x2dC55ec5fC4a5D2dDd662f747F3a4f1784F34eEC"

async function main() {
  try {
    await contract.methods.executeSwap().send({ from: myAddress, gas: '800000' })  
  } catch (err) {
    console.log("An error occurred", err)
  }
}

main()










