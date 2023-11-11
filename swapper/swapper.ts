// import { ethers } from '../node_modules/ethers';
// import { constructSimpleSDK, SwapSide } from '../node_modules/@paraswap/sdk';
// import axios from 'axios';

const ethers = require('../node_modules/ethers');
const { constructSimpleSDK, SwapSide } = require('../node_modules/@paraswap/sdk');
const axios = require('axios');
const paraSwap = constructSimpleSDK({ chainId: 137, axios });

const USDC = '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174';
const SAND = '0xBbba073C31bF03b8ACf7c28EF0738DeCF3695683';

async function swapUSDCtoSAND() {
  // const signer: ethers.providers.JsonRpcSigner = new ethers.providers.Web3Provider(
  //   window.ethereum
  // ).getSigner();
  const senderAddress = ethers.Wallet.fromMnemonic("grass permit accident owner lock above hello stick divide cigar void language").address;
  //const senderAddress = await signer.getAddress();
  await console.log("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!TEST0!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
  const priceRoute = await paraSwap.swap.getRate({
    srcToken: USDC,
    srcDecimals: 6,
    destToken: SAND,
    destDecimals: 18,
    amount: '1000000000000000000', // 1 USDC
    userAddress: senderAddress,
    side: SwapSide.SELL,
  });

  await console.log("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!TEST1!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
  // const txParams = await paraSwap.swap.buildTx({
  //   srcToken: USDC,
  //   destToken: MATIC,
  //   srcAmount: '1000000000000000000', // 1 USDC
  //   destAmount: priceRoute.destAmount,
  //   priceRoute,
  //   userAddress: senderAddress,
  // });

  console.log("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!TEST2!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");

  // const transaction = {
  //   ...txParams,
  //   gasPrice: '0x' + new ethers.BigNumber({}, txParams.gasPrice).toString(),
  //   gasLimit: '0x' + new ethers.BigNumber({}, "5000000").toString(),
  //   value: '0x' + new ethers.BigNumber({}, txParams.value).toString(),
  // };

  // const txr = await signer.sendTransaction(transaction);
  console.log("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
  //console.log(transaction);
}

swapUSDCtoSAND();
