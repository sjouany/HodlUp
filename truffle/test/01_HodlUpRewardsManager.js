const HodlUpRewardsManager = artifacts.require("./HodlUpRewardsManager.sol");
const Hodl = artifacts.require("./Hodl.sol");
const { BN, expectRevert, expectEvent, time } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const ERC20TransferABI = require ("../../client/src/contracts/IERC20.json");

contract('HodlUpRewardsManager', accounts => {
    const owner = accounts[0];
    const user1 = accounts[1];
    const user2 = accounts[2];

    const SAND_ADDRESS = "0xBbba073C31bF03b8ACf7c28EF0738DeCF3695683";
    const SAND_ORACLE_ADDRESS="0x3D49406EDd4D52Fb7FFd25485f32E073b529C924";
    let HodlUpRewardsManagerInstance;

    describe("test constructor", function () {
        it("should be initialize contract states", async () => {
            HodlInstance = await Hodl.new();
            HodlUpRewardsManagerInstance = await HodlUpRewardsManager.new(HodlInstance.address, 500)
            expect(await HodlUpRewardsManagerInstance.rewardApy.call()).to.be.bignumber.equal(new BN(500));
            const token = await HodlUpRewardsManagerInstance.rewardToken.call();
            expect(token).to.equal(HodlInstance.address);
        });
    });

    describe("test setter", function () {
        
        beforeEach(async function () {
            HodlInstance = await Hodl.new();
            HodlUpRewardsManagerInstance = await HodlUpRewardsManager.new(HodlInstance.address, 500)
        });

        it("should not set APY (Only Owner)", async () => {
            expectRevert(HodlUpRewardsManagerInstance.setApy(200,  {from: user1}), 'Ownable: caller is not the owner');
        });

        it("should set APY", async () => {
            await HodlUpRewardsManagerInstance.setApy(200,  {from: owner});
            expect(await HodlUpRewardsManagerInstance.rewardApy.call()).to.be.bignumber.equal(new BN(200));
        });

        it("should not set Reward Token (Only Owner)", async () => {
            expectRevert(HodlUpRewardsManagerInstance.setRewardToken(SAND_ADDRESS,  {from: user1}), 'Ownable: caller is not the owner');
        });

        it("should set Reward Token", async () => {
            await HodlUpRewardsManagerInstance.setRewardToken(SAND_ADDRESS,  {from: owner});
            expect(await HodlUpRewardsManagerInstance.rewardToken.call()).to.equal(SAND_ADDRESS);
        }); 

        it("should not add Oracle (Only Owner)", async () => {
            expectRevert(HodlUpRewardsManagerInstance.addOracle(SAND_ADDRESS, SAND_ORACLE_ADDRESS,  {from: user1}), 'Ownable: caller is not the owner');
        });         

        it("should add Oracle", async () => {
            await HodlUpRewardsManagerInstance.addOracle(SAND_ADDRESS, SAND_ORACLE_ADDRESS,  {from: owner});
            oracle = await HodlUpRewardsManagerInstance.oracles.call(SAND_ADDRESS);
            expect(oracle).to.equal(SAND_ORACLE_ADDRESS);
        }); 

        it("should not add Contract", async () => {
            expectRevert(HodlUpRewardsManagerInstance.addContract(SAND_ADDRESS,  {from: user1}), 'Ownable: caller is not the owner' );
        }); 

        it("should add Contract", async () => {
            it("should add Oracle", async () => {
                await HodlUpRewardsManagerInstance.addContract(SAND_ADDRESS,  {from: owner});
                contractAuthorized = await HodlUpRewardsManagerInstance.authorizedContracts.call(SAND_ADDRESS);
                expect(contractAuthorized).to.true;
            }); 
        }); 

        it("should add Contract (event)", async () => {
            it("should add Oracle", async () => {
                await HodlUpRewardsManagerInstance.addContract(SAND_ADDRESS,  {from: owner});
                contractAuthorized = await HodlUpRewardsManagerInstance.authorizedContracts.call(SAND_ADDRESS);
                expectEvent(await HodlUpRewardsManagerInstance.addContract(SAND_ADDRESS,  {from: owner}), "ContractAdded", {address: USDC_ADDRESS} );
            }); 
        }); 
    });   

    describe("test reward management", function () {

        beforeEach(async function () {
            HodlInstance = await Hodl.new();
            HodlUpRewardsManagerInstance = await HodlUpRewardsManager.new(HodlInstance.address, 500)
            expectedAmountnew = BN(10000).mul(BN(10).pow(new BN(18)));
            await HodlInstance.mint(owner, expectedAmountnew,  {from: owner});
            await HodlUpRewardsManagerInstance.addContract(owner,  {from: owner});
            await HodlUpRewardsManagerInstance.addOracle(SAND_ADDRESS, SAND_ORACLE_ADDRESS,  {from: owner});
        });

        it("should get the USD price for SAND", async () => {
            const token = await HodlUpRewardsManagerInstance.getUSDPriceFromOracle(SAND_ADDRESS,  {from: user1});
            expect(BN(token)).to.be.bignumber.greaterThan(new BN(0));
        });
    });
});