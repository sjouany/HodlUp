
const USDC_ADDRESS = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174"
const SAND_ADDRESS = "0xBbba073C31bF03b8ACf7c28EF0738DeCF3695683"
const SAND_ORACLE = "0x3D49406EDd4D52Fb7FFd25485f32E073b529C924"
const UNISWAP_ROUTER_ADDRESS = "0xE592427A0AEce92De3Edee1F18E0157C05861564";
const DEPOSIT_FEE = 50;
const SWAP_FEE = 20;
const DcaHodlup = artifacts.require("DcaHodlup");


module.exports = async (deployer, network, accounts) => {
    await deployer.deploy(DcaHodlup, USDC_ADDRESS, SAND_ADDRESS, UNISWAP_ROUTER_ADDRESS, SWAP_FEE, { from: accounts[0] });

    let dcaHodlup = await DcaHodlup.deployed();
    // Chainlink Price feeds addresses POLYGON MAINNET
    // SAND / USD => 0x3D49406EDd4D52Fb7FFd25485f32E073b529C924
    // MATIC / USD => 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
    // LINK / USD => 0xd9FFdb71EbE7496cC440152d43986Aae0AB76665
    //await dcaHodlup.addInterval(1, { from: accounts[0] });
    //await dcaHodlup.addPair(USDC_ADDRESS, SAND_ADDRESS, true, { from: accounts[0] });
} 
