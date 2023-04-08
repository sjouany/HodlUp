
const Web3 = require("web3")
const web3 = new Web3("http://localhost:8545")

const contractABIQ = require("/home/sjouany/ProjetFinal/HodlUp/client/src/contracts/HodlUpHub.json")

const contractAddress = "0x1670A50E15a4d350fF093482614B9E82BF0B3D69"
const contract = new web3.eth.Contract(contractABIQ.abi, contractAddress)
const myAddress = "0x2dC55ec5fC4a5D2dDd662f747F3a4f1784F34eEC"

async function main() {
  try {
    await contract.methods.addInterval("1")
    .send({ from: myAddress, gas: '500000' })
    
    await contract.methods.addPair('0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174', '0xBbba073C31bF03b8ACf7c28EF0738DeCF3695683', true)
    .send({ from: myAddress, gas: '500000' })
    
    await contract.methods.createPosition("test", ["0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174","0xBbba073C31bF03b8ACf7c28EF0738DeCF3695683",true], "100000000000", "1", "1")
    .send({ from: myAddress, gas: '500000' })

    await contract.methods.createPosition("test", ["0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174","0xBbba073C31bF03b8ACf7c28EF0738DeCF3695683",true], "100000000000", "1", "1")
    .send({ from: myAddress, gas: '500000' })

    // await contract.methods.executeDCA()
    // .send({ from: myAddress, gas: '500000' })  

    // position sand
    await contract.methods.addPair('0xBbba073C31bF03b8ACf7c28EF0738DeCF3695683', '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174', true)
    .send({ from: myAddress, gas: '500000' })

    await contract.methods.createPosition("test", ["0xBbba073C31bF03b8ACf7c28EF0738DeCF3695683","0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174",true], "1000000000000000000", "1", "1")
    .send({ from: myAddress, gas: '500000' })

    await contract.methods.createPosition("test", ["0xBbba073C31bF03b8ACf7c28EF0738DeCF3695683","0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174",true], "1000000000000000000", "1", "1")
    .send({ from: myAddress, gas: '500000' })

    await contract.methods.executeDCA()
    .send({ from: myAddress, gas: '500000' })  

  } catch (err) {
    console.log("An error occurred", err)
  }
}

main()










