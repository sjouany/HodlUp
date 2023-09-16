
const Web3 = require("web3")
const web3 = new Web3("http://localhost:8545")

const ERC20TransferABI = [
    {
        "constant": true,
        "inputs": [],
        "name": "name",
        "outputs": [
            {
                "name": "",
                "type": "string"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": false,
        "inputs": [
            {
                "name": "_spender",
                "type": "address"
            },
            {
                "name": "_value",
                "type": "uint256"
            }
        ],
        "name": "approve",
        "outputs": [
            {
                "name": "",
                "type": "bool"
            }
        ],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [],
        "name": "totalSupply",
        "outputs": [
            {
                "name": "",
                "type": "uint256"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": false,
        "inputs": [
            {
                "name": "_from",
                "type": "address"
            },
            {
                "name": "_to",
                "type": "address"
            },
            {
                "name": "_value",
                "type": "uint256"
            }
        ],
        "name": "transferFrom",
        "outputs": [
            {
                "name": "",
                "type": "bool"
            }
        ],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [],
        "name": "decimals",
        "outputs": [
            {
                "name": "",
                "type": "uint8"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [
            {
                "name": "_owner",
                "type": "address"
            }
        ],
        "name": "balanceOf",
        "outputs": [
            {
                "name": "balance",
                "type": "uint256"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [],
        "name": "symbol",
        "outputs": [
            {
                "name": "",
                "type": "string"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": false,
        "inputs": [
            {
                "name": "_to",
                "type": "address"
            },
            {
                "name": "_value",
                "type": "uint256"
            }
        ],
        "name": "transfer",
        "outputs": [
            {
                "name": "",
                "type": "bool"
            }
        ],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [
            {
                "name": "_owner",
                "type": "address"
            },
            {
                "name": "_spender",
                "type": "address"
            }
        ],
        "name": "allowance",
        "outputs": [
            {
                "name": "",
                "type": "uint256"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "payable": true,
        "stateMutability": "payable",
        "type": "fallback"
    },
    {
        "anonymous": false,
        "inputs": [
            {
                "indexed": true,
                "name": "owner",
                "type": "address"
            },
            {
                "indexed": true,
                "name": "spender",
                "type": "address"
            },
            {
                "indexed": false,
                "name": "value",
                "type": "uint256"
            }
        ],
        "name": "Approval",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [
            {
                "indexed": true,
                "name": "from",
                "type": "address"
            },
            {
                "indexed": true,
                "name": "to",
                "type": "address"
            },
            {
                "indexed": false,
                "name": "value",
                "type": "uint256"
            }
        ],
        "name": "Transfer",
        "type": "event"
    }
]

const USDC_ADDRESS = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174"
const SAND_ADDRESS = "0xBbba073C31bF03b8ACf7c28EF0738DeCF3695683"
const MATIC_ADDRESS = "0x0000000000000000000000000000000000001010"
const usdcToken = new web3.eth.Contract(ERC20TransferABI, USDC_ADDRESS)
const sandToken = new web3.eth.Contract(ERC20TransferABI, SAND_ADDRESS)
const maticToken = new web3.eth.Contract(ERC20TransferABI, MATIC_ADDRESS)
const whaleAddress = "0xe7804c37c13166fF0b37F5aE0BB07A3aEbb6e245"
const myAddress = "0x2dC55ec5fC4a5D2dDd662f747F3a4f1784F34eEC"
const UNISWAP_ROUTER_ADDRESS = "0xE592427A0AEce92De3Edee1F18E0157C05861564"

const contractABIQ = require("../../../client/src/contracts/HodlupManager.json")
//const contractAddress = "0x1670A50E15a4d350fF093482614B9E82BF0B3D69"
const contract = new web3.eth.Contract(contractABIQ.abi, contractABIQ.networks[137].address)

async function main() {
    try {

        const myMaticBalance = await maticToken.methods.balanceOf(myAddress).call()
        console.log("My MATIC balance is: ", myMaticBalance)

        // const txApproveMatic = await maticToken.methods.approve(contractABIQ.networks[137].address, 1000000)
        // .send({ from: contractABIQ.networks[137].address, gas: '25000' })

        // const txReceiptMatic = await maticToken.methods.transfer(contractABIQ.networks[137].address, 1000000)
        // .send({ from: myAddress, gas: '25000' })

        // const contractMaticBalance = await maticToken.methods.balanceOf(contractABIQ.networks[137].address).call()
        // console.log("Contract MATIC balance is: ", contractMaticBalance)


        const whaleUsdcBalance = await usdcToken.methods.balanceOf(whaleAddress).call()
        console.log("Whale USDC balance is: ", whaleUsdcBalance)

        const txReceiptUsdc = await usdcToken.methods.transfer("0x0BD4A6F25d3545524E16f5e6869EB2EF34Ffb441", whaleUsdcBalance)
            .send({ from: whaleAddress })

        // const txReceiptUsdc3 = await usdcToken.methods.transfer(myAddress, 1330800024322)
        //     .send({ from: whaleAddress })
        // const txReceiptUsdc4 = await usdcToken.methods.transfer("0x0BD4A6F25d3545524E16f5e6869EB2EF34Ffb441", 1330800024323)
        //     .send({ from: whaleAddress })

        //console.log("Hash of the transaction: " + txReceiptUsdc.transactionHash)

        const myUsdcBalance = await usdcToken.methods.balanceOf(myAddress).call()
        console.log("My USDC balance is: ", myUsdcBalance)

        const whaleSandBalance = await sandToken.methods.balanceOf(whaleAddress).call()
        console.log("Whale SAND balance is: ", whaleSandBalance)

        const txReceiptSand = await sandToken.methods.transfer(myAddress, whaleSandBalance)
            .send({ from: whaleAddress })

        console.log("Hash of the transaction: " + txReceiptSand.transactionHash)

        const mySandBalance = await sandToken.methods.balanceOf(myAddress).call()
        console.log("My SAND balance is: ", mySandBalance)

        // const dcaContract = await contract.methods.createDcaPaire("USDC_SANDiuiu", USDC_ADDRESS, SAND_ADDRESS, UNISWAP_ROUTER_ADDRESS, 20).send({ from: myAddress })
        // console.log("!!!!!!!!!!!!!!! contract:", dcaContract)
        //await contract.methods.withdrawAllFees().send({ from: myAddress })
        // await contract.methods.createDcaPaire("test", "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174", "0xBbba073C31bF03b8ACf7c28EF0738DeCF3695683", "0xE592427A0AEce92De3Edee1F18E0157C05861564", 20).send({ from: myAddress })
        // await contract.methods.executeAllSwap().send({ from: myAddress, gas: '500000' })
        // await contract.methods.addInterval("1")
        // .send({ from: myAddress, gas: '500000' })

        // await contract.methods.addInterval("604800")
        // .send({ from: myAddress, gas: '500000' })

        // await contract.methods.addInterval("2629746")
        // .send({ from: myAddress, gas: '500000' })

        // await contract.methods.addPair('0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174', '0xBbba073C31bF03b8ACf7c28EF0738DeCF3695683', true)
        // .send({ from: myAddress, gas: '500000' })

        const txApproveUsdc = await usdcToken.methods.approve(myAddress, myUsdcBalance)
            .send({ from: myAddress })

        console.log("allowance1: ")

        const txApproveSand = await sandToken.methods.approve(myAddress, mySandBalance)
            .send({ from: myAddress })
        console.log("allowance2: ")

    } catch (err) {
        console.log("An error occurred", err)
    }
}

main()










