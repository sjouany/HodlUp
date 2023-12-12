// import { ethers } from '../node_modules/ethers';
// import { constructSimpleSDK, SwapSide } from '../node_modules/@paraswap/sdk';
// import axios from 'axios';
const contractABI = [
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "address",
        "name": "user",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "string",
        "name": "name",
        "type": "string"
      },
      {
        "indexed": false,
        "internalType": "address",
        "name": "token_from",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "address",
        "name": "token_to",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "amountToSwap",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "amountSwapped",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "date",
        "type": "uint256"
      }
    ],
    "name": "DCAExecuted",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "previousOwner",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "newOwner",
        "type": "address"
      }
    ],
    "name": "OwnershipTransferred",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "sender",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "address",
        "name": "token_from",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "address",
        "name": "token_to",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "string",
        "name": "name",
        "type": "string"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "date",
        "type": "uint256"
      }
    ],
    "name": "PositionCreated",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "sender",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "address",
        "name": "token_from",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "address",
        "name": "token_to",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "string",
        "name": "name",
        "type": "string"
      },
      {
        "indexed": false,
        "internalType": "enum DcaHodlup.Status",
        "name": "status",
        "type": "uint8"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "date",
        "type": "uint256"
      }
    ],
    "name": "PositionStatusChanged",
    "type": "event"
  },
  {
    "inputs": [],
    "name": "Paraswap",
    "outputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "ParaswapProxy",
    "outputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "claimFees",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "fees",
        "type": "uint256"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "string",
        "name": "_name",
        "type": "string"
      }
    ],
    "name": "closePosition",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "string",
        "name": "_name",
        "type": "string"
      },
      {
        "internalType": "uint256",
        "name": "_totalAmountToSwap",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "_interval",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "_amountPerSwap",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "_dcaIterations",
        "type": "uint256"
      }
    ],
    "name": "createPosition",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "executeSwap",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "string",
        "name": "_name",
        "type": "string"
      }
    ],
    "name": "getPosition",
    "outputs": [
      {
        "components": [
          {
            "internalType": "string",
            "name": "name",
            "type": "string"
          },
          {
            "internalType": "uint256",
            "name": "totalAmountToSwap",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "interval",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "dcaIterations",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "amountPerSwap",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "lastPurchaseTimestamp",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "createdTimestamp",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "SwappedFromBalance",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "SwappedToBalance",
            "type": "uint256"
          },
          {
            "internalType": "enum DcaHodlup.Status",
            "name": "status",
            "type": "uint8"
          },
          {
            "internalType": "address",
            "name": "recipient",
            "type": "address"
          },
          {
            "internalType": "enum DcaHodlup.DcaMode",
            "name": "mode",
            "type": "uint8"
          }
        ],
        "internalType": "struct DcaHodlup.Position",
        "name": "",
        "type": "tuple"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "user",
        "type": "address"
      }
    ],
    "name": "getPositionsToSwap",
    "outputs": [
      {
        "components": [
          {
            "internalType": "string",
            "name": "name",
            "type": "string"
          },
          {
            "internalType": "uint256",
            "name": "totalAmountToSwap",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "interval",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "dcaIterations",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "amountPerSwap",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "lastPurchaseTimestamp",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "createdTimestamp",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "SwappedFromBalance",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "SwappedToBalance",
            "type": "uint256"
          },
          {
            "internalType": "enum DcaHodlup.Status",
            "name": "status",
            "type": "uint8"
          },
          {
            "internalType": "address",
            "name": "recipient",
            "type": "address"
          },
          {
            "internalType": "enum DcaHodlup.DcaMode",
            "name": "mode",
            "type": "uint8"
          }
        ],
        "internalType": "struct DcaHodlup.Position[]",
        "name": "",
        "type": "tuple[]"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_inputToken",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "_outputToken",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "_uniswapRouter",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "_swapFee",
        "type": "uint256"
      }
    ],
    "name": "initialize",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "owner",
    "outputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "renounceOwnership",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "string",
        "name": "_name",
        "type": "string"
      },
      {
        "internalType": "enum DcaHodlup.Status",
        "name": "_status",
        "type": "uint8"
      }
    ],
    "name": "setPositionStatus",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "swapFee",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_userAddress",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "_inputToken",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "_amount",
        "type": "uint256"
      },
      {
        "internalType": "address",
        "name": "_outputToken",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "receiver",
        "type": "address"
      },
      {
        "internalType": "bytes",
        "name": "_swapdata",
        "type": "bytes"
      }
    ],
    "name": "swapIt",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "newOwner",
        "type": "address"
      }
    ],
    "name": "transferOwnership",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "name": "userAddresses",
    "outputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  }
];

require('axios-debug-log');
const ethers = require('../node_modules/ethers');
const { constructSimpleSDK, SwapSide } = require('../node_modules/@paraswap/sdk');
const axios = require('axios');
const paraSwap = constructSimpleSDK({ chainId: 137, axios });

//const infuraApiKey = 'your-infura-api-key';
//const provider = new ethers.providers.JsonRpcProvider(`https://polygon-mainnet.g.alchemy.com/v2/E_47dJ_8PBLE24COiPQ1hcE1ZIBVgcps`);
const provider = new ethers.providers.JsonRpcProvider('http://localhost:8545', { chainId: 1337 })
const privateKey = '1cb6b88475450355d47a03fdc3039cd31de6381198542b927e03a38416a320b1';
const wallet = new ethers.Wallet(privateKey, provider);


const USDC = '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174';
const SAND = '0xBbba073C31bF03b8ACf7c28EF0738DeCF3695683';
const contractAddress = "0x29E672550D2841Dac7ff21f345b6968A27DF6248";
const contract = new ethers.Contract(contractAddress, contractABI, wallet);
const amount = 1234567891;

async function swapUSDCtoSAND() {
  //   const signer: ethers.providers.JsonRpcSigner = new ethers.providers.Web3Provider(
  //      window.ethereum
  //  ).getSigner();
  // provider = new ethers.providers.Web3Provider(web3.currentProvider);

  //const senderAddress = ethers.Wallet.fromMnemonic("grass permit accident owner lock above hello stick divide cigar void language").address;
  const senderAddress = wallet.address
  console.log("???????????????wallet:", wallet.address);

  // const network = await provider.getNetwork();
  // console.log("?.?.?.?.?.?.?.?.?:",network.chainId);
  console.log("!!!!!!!:::::::::", wallet)
  console.log("Transaction complete!");
  //const senderAddress = await signer.getAddress();
  await console.log("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!TEST0!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
  const priceRoute = await paraSwap.swap.getRate({
    srcToken: USDC,
    srcDecimals: 6,
    destToken: SAND,
    destDecimals: 18,
    amount: amount.toString(), // 1 USDC
    userAddress: contractAddress,
    side: SwapSide.SELL,
  });

  await console.log("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!TEST1!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
  await console.log(priceRoute);
  const txParams = await paraSwap.swap.buildTx({
    srcToken: USDC,
    destToken: SAND,
    srcAmount: amount.toString(), // 1 USDC
    destAmount: priceRoute.destAmount,
    priceRoute,
    userAddress: contractAddress,
  },
    { ignoreChecks: true });

  console.log("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!TEST2!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!:", txParams.gasPrice);

  const transaction = {
    ...txParams,
    //gasPrice: '0x' + ethers.BigNumber.from(txParams.gasPrice).toString(),
    gasPrice: '0x' + ethers.BigNumber.from("5000000000000").toString(),

    //gasLimit: '0x' + ethers.BigNumber.from("5000000").toString(),
    gasLimit: '0x' + ethers.BigNumber.from("5000000000000").toString(),
    value: '0x' + ethers.BigNumber.from(txParams.value).toString(),
  };

  // const txr = await signer.sendTransaction(transaction);
  console.log("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
  console.log(transaction);
  console.log("!!!!!data:", transaction.data)

  // Créer une instance du contrat ERC20 (USDC)
  const usdcContract = new ethers.Contract(USDC, ['function approve(address spender, uint256 amount)',
    'function allowance(address owner, address spender) external view returns (uint256)'], wallet);

  // Approve - Autoriser Paraswap à dépenser un montant donné
  //const amountToApprove = ethers.utils.parseUnits('AMOUNT_TO_APPROVE', 'wei'); // Remplacez par le montant que vous souhaitez autoriser
  var allowanceTx = await usdcContract.allowance(senderAddress, contractAddress, { gasPrice: 5000000000000, gasLimit: 3e7 });
  //await allowanceTx.wait();
  console.log("????????????? allowance USDC/contract(avant):", allowanceTx.toString());

  const approveTx = await usdcContract.approve(contractAddress, amount, { gasPrice: 5000000000000, gasLimit: 3e7 });
  await approveTx.wait();

  allowanceTx = await usdcContract.allowance(senderAddress, contractAddress, { gasPrice: 5000000000000, gasLimit: 3e7 });
  console.log("????????????? allowance USDC/contract(apres):", allowanceTx.toString());

  allowanceTx = await usdcContract.allowance(contractAddress, "0x216B4B4Ba9F3e719726886d34a177484278Bfcae", { gasPrice: 5000000000000, gasLimit: 3e7 });
  console.log("????????????? allowance contract/proxy(avant):", allowanceTx.toString());
  //const approveTx2 = await usdcContract.approve(contractAddress, 1234567891, { gasPrice: 5000000000000 });
  //await approveTx2.wait();

  const tx = await contract.swapIt(
    wallet.address,
    USDC,
    amount,
    SAND,
    wallet.address,
    transaction.data, { gasPrice: 5000000000000, gasLimit: 3e7 }
  );
  await tx.wait();

  allowanceTx = await usdcContract.allowance(contractAddress, "0x216B4B4Ba9F3e719726886d34a177484278Bfcae", { gasPrice: 5000000000000, gasLimit: 3e7 });
  console.log("????????????? allowance contract/proxy(apres):", allowanceTx.toString());
}

swapUSDCtoSAND();
