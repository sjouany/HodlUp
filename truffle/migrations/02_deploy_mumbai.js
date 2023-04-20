const USDC_ADDRESS = "0xe11A86849d99F524cAC3E7A0Ec1241828e332C62"
const SAND_ADDRESS = "0xE03489D4E90b22c59c5e23d45DFd59Fc0dB8a025"
const MATIC_ADDRESS = "0x0000000000000000000000000000000000001010"
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
    // Chainlink Price feeds addresses POLYGON MAINNET
    // SAND / USD => 0x3D49406EDd4D52Fb7FFd25485f32E073b529C924
    // MATIC / USD => 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
    // LINK / USD => 0xd9FFdb71EbE7496cC440152d43986Aae0AB76665
    await deployer.deploy(HodlUpHub, UNISWAP_ROUTER_ADDRESS, hodlUpRewardsManager.address, DEPOSIT_FEE, SWAP_FEE, { from: accounts[0] });
    await hodl.mint(hodlUpRewardsManager.address, 1000000000,  { from: accounts[0] });
    console.log("mint");
    let hodlUpHub =  await HodlUpHub.deployed();
    // 1s Interval to show swap during demo
    console.log("interval 1");
    await hodlUpHub.addInterval(1, { from: accounts[0] });
    // Week
    console.log("interval 604800");
    await hodlUpHub.addInterval(604800, { from: accounts[0] });
    // Month
    console.log("interval 2629746");
    await hodlUpHub.addInterval(2629746, { from: accounts[0] });
    // USDC / SAND
    console.log("PAIR USDC/SAND");
    await hodlUpHub.addPair(USDC_ADDRESS, SAND_ADDRESS, true, { from: accounts[0] });
    // USDC / MATIC
    console.log("PAIR USDC/MATIC");
    await hodlUpHub.addPair(USDC_ADDRESS, MATIC_ADDRESS, true, { from: accounts[0] });
} 
