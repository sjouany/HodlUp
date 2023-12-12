
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

const contractABIQ = require("../../../client/src/contracts/HodlupManager.json")
const USDC_ADDRESS = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174"
const SAND_ADDRESS = "0xBbba073C31bF03b8ACf7c28EF0738DeCF3695683"
const usdcToken = new web3.eth.Contract(ERC20TransferABI, USDC_ADDRESS)
const sandToken = new web3.eth.Contract(ERC20TransferABI, SAND_ADDRESS)
const whaleAddress = "0xe7804c37c13166fF0b37F5aE0BB07A3aEbb6e245"
const myAddress = "0x2dC55ec5fC4a5D2dDd662f747F3a4f1784F34eEC"
const contract = new web3.eth.Contract(contractABIQ.abi, contractABIQ.networks[137].address)

const contractDeployed = "0x29E672550D2841Dac7ff21f345b6968A27DF6248"

async function main() {
    try {
        const whaleUsdcBalance = await usdcToken.methods.balanceOf(whaleAddress).call()
        console.log("Whale USDC balance is: ", whaleUsdcBalance)

        const whaleSandBalance = await sandToken.methods.balanceOf(whaleAddress).call()
        console.log("Whale SAND balance is: ", whaleSandBalance)

        const myUsdcBalance = await usdcToken.methods.balanceOf(myAddress).call()
        console.log("My USDC balance is: ", myUsdcBalance)

        const mySandBalance = await sandToken.methods.balanceOf(myAddress).call()
        console.log("My SAND balance is: ", mySandBalance)

        const contractUsdcBalance = await usdcToken.methods.balanceOf(contractABIQ.networks[137].address).call()
        console.log("CONTRACT USDC balance is: ", contractUsdcBalance)

        const contractSandBalance = await sandToken.methods.balanceOf(contractABIQ.networks[137].address).call()
        console.log("CONTRACT SAND balance is: ", contractSandBalance)

        // const txApproveUsdc = await usdcToken.methods.approve(contractDeployed, 1000000000000);
        // console.log("TX: ", txApproveUsdc)
        const myUsdcBalance2 = await usdcToken.methods.balanceOf("0x0BD4A6F25d3545524E16f5e6869EB2EF34Ffb441").call()
        console.log("F34Ffb441 USDC balance is: ", myUsdcBalance2)

        const myUsdcBalance3 = await sandToken.methods.balanceOf("0x0BD4A6F25d3545524E16f5e6869EB2EF34Ffb441").call()
        console.log("F34Ffb441 SAND balance is: ", myUsdcBalance3)

        const tempcontractUsdcBalance = await usdcToken.methods.balanceOf(contractDeployed).call()
        console.log("TEMP CONTRACT USDC balance is: ", tempcontractUsdcBalance)

        const tempcontractUsdcBalance2 = await sandToken.methods.balanceOf(contractDeployed).call()
        console.log("TEMP CONTRACT SAND balance is: ", tempcontractUsdcBalance2)

    } catch (err) {
        console.log("An error occurred", err)
    }
}

main()










