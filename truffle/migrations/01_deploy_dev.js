
const USDC_ADDRESS = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174"
const SAND_ADDRESS = "0xBbba073C31bF03b8ACf7c28EF0738DeCF3695683"
const SAND_ORACLE = "0x3D49406EDd4D52Fb7FFd25485f32E073b529C924"
const UNISWAP_ROUTER_ADDRESS = "0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff";
const DEPOSIT_FEE = 50;
const SWAP_FEE = 20;
const Hodl = artifacts.require("Hodl");
const HodlUpHub = artifacts.require("HodlUpHub");
const HodlUpRewardsManager = artifacts.require("HodlUpRewardsManager");

module.exports = async(deployer, network, accounts) => {
    await deployer.deploy(Hodl);
	let hodl = await Hodl.deployed();
    await deployer.deploy(HodlUpRewardsManager, hodl.address, 600);
	let hodlUpRewardsManager = await HodlUpRewardsManager.deployed(); 
    await deployer.deploy(HodlUpHub, UNISWAP_ROUTER_ADDRESS, hodlUpRewardsManager.address, DEPOSIT_FEE, SWAP_FEE, { from: accounts[0] });
    await hodl.mint(hodlUpRewardsManager.address, 1000000000,  { from: accounts[0] });
    let hodlUpHub =  await HodlUpHub.deployed();
    await hodlUpRewardsManager.addContract(hodlUpHub.address, { from: accounts[0] });
    // Chainlink Price feeds addresses POLYGON MAINNET
    // SAND / USD => 0x3D49406EDd4D52Fb7FFd25485f32E073b529C924
    // MATIC / USD => 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
    // LINK / USD => 0xd9FFdb71EbE7496cC440152d43986Aae0AB76665
    await hodlUpRewardsManager.addOracle(SAND_ADDRESS, SAND_ORACLE, { from: accounts[0] });
    await hodlUpHub.addInterval(1, { from: accounts[0] });
    await hodlUpHub.addPair(USDC_ADDRESS, SAND_ADDRESS, true, { from: accounts[0] });
} 
