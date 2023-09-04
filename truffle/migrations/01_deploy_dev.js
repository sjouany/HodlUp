
const USDC_ADDRESS = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174"
const SAND_ADDRESS = "0xBbba073C31bF03b8ACf7c28EF0738DeCF3695683"
const SAND_ORACLE = "0x3D49406EDd4D52Fb7FFd25485f32E073b529C924"
const UNISWAP_ROUTER_ADDRESS = "0xE592427A0AEce92De3Edee1F18E0157C05861564";
const DEPOSIT_FEE = 50;
const SWAP_FEE = 20;
const DcaHodlup = artifacts.require("DcaHodlup");
const HodlupManager = artifacts.require("HodlupManager");
const Ierc20 = artifacts.require("IERC20");



module.exports = async (deployer, network, accounts) => {
    //await deployer.deploy(DcaHodlup, USDC_ADDRESS, SAND_ADDRESS, UNISWAP_ROUTER_ADDRESS, SWAP_FEE, { from: accounts[0] });
//    let dcaHodlup = await DcaHodlup.deployed();
    await deployer.deploy(HodlupManager, { from: accounts[0] });
    let hodlupManager = await HodlupManager.deployed();
    await hodlupManager.createDcaPaire("USDC_SAND", USDC_ADDRESS, SAND_ADDRESS, UNISWAP_ROUTER_ADDRESS, 20, { from: accounts[0] })
    .on('transactionHash', function (hash) {
        console.log('Transaction hash:', hash);
      })
      .on('receipt', function (receipt) {
        console.log('Transaction receipt:', receipt);
      })
      .on('error', function (error) {
        console.error('Error:', error);
      });



    let usdcSandContractAdress= await hodlupManager.dcaContracts.call("USDC_SAND", { from: accounts[0] })
    console.log("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!:", usdcSandContractAdress)

    var usdcSandContract = await DcaHodlup.at(usdcSandContractAdress);

    await usdcSandContract.createPosition("test1", 1000000, 3, 10000, 0, { from: accounts[0] })
    await usdcSandContract.createPosition("test2", 2000000, 3, 10000, 0, { from: accounts[0] })
    await usdcSandContract.createPosition("test3", 3000000, 3, 10000, 0, { from: accounts[0] })

    var usdcContract = await Ierc20.at(USDC_ADDRESS);

    // Chainlink Price feeds addresses POLYGON MAINNET
    // SAND / USD => 0x3D49406EDd4D52Fb7FFd25485f32E073b529C924
    // MATIC / USD => 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
    // LINK / USD => 0xd9FFdb71EbE7496cC440152d43986Aae0AB76665
    //await dcaHodlup.addInterval(1, { from: accounts[0] });
    //await dcaHodlup.addPair(USDC_ADDRESS, SAND_ADDRESS, true, { from: accounts[0] });
} 
