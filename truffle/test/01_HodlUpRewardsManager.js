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
        xit("should be initialize contract states", async () => {
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

        xit("should not set APY (Only Owner)", async () => {
            expectRevert(HodlUpRewardsManagerInstance.setApy(200,  {from: user1}), 'Ownable: caller is not the owner');
        });

        xit("should set APY", async () => {
            await HodlUpRewardsManagerInstance.setApy(200,  {from: owner});
            expect(await HodlUpRewardsManagerInstance.rewardApy.call()).to.be.bignumber.equal(new BN(200));
        });

        xit("should not set Reward Token (Only Owner)", async () => {
            expectRevert(HodlUpRewardsManagerInstance.setRewardToken(SAND_ADDRESS,  {from: user1}), 'Ownable: caller is not the owner');
        });

        xit("should set Reward Token", async () => {
            await HodlUpRewardsManagerInstance.setRewardToken(SAND_ADDRESS,  {from: owner});
            expect(await HodlUpRewardsManagerInstance.rewardToken.call()).to.equal(SAND_ADDRESS);
        }); 

        xit("should not add Oracle (Only Owner)", async () => {
            expectRevert(HodlUpRewardsManagerInstance.addOracle(SAND_ADDRESS, SAND_ORACLE_ADDRESS,  {from: user1}), 'Ownable: caller is not the owner');
        });         

        xit("should add Oracle", async () => {
            await HodlUpRewardsManagerInstance.addOracle(SAND_ADDRESS, SAND_ORACLE_ADDRESS,  {from: owner});
            oracle = await HodlUpRewardsManagerInstance.oracles.call(SAND_ADDRESS);
            expect(oracle).to.equal(SAND_ORACLE_ADDRESS);
        }); 

        xit("should not add Contract", async () => {
            expectRevert(HodlUpRewardsManagerInstance.addContract(SAND_ADDRESS,  {from: user1}), 'Ownable: caller is not the owner' );
        }); 

        xit("should add Contract", async () => {
            xit("should add Oracle", async () => {
                await HodlUpRewardsManagerInstance.addContract(SAND_ADDRESS,  {from: owner});
                contractAuthorized = await HodlUpRewardsManagerInstance.authorizedContracts.call(SAND_ADDRESS);
                expect(contractAuthorized).to.true;
            }); 
        }); 

        xit("should add Contract (event)", async () => {
            xit("should add Oracle", async () => {
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

        it("should not get the USD price for SAND", async () => {
            await console.log("!???????!");
            const token = await HodlUpRewardsManagerInstance.getUSDPriceFromOracle(owner,  {from: user1});
            await console.log("!!!!!!!!!!!!");
            await console.log(token)
            expect(BN(token)).to.be.bignumber.greaterThan(new BN(0));
        });
    });

    // function getUSDPriceFromOracle(address _token) public view returns (uint256) {
    //     (, int256 price, , ,) = AggregatorV3Interface(oracles[_token]).latestRoundData();
    //     require(price > 0, "TokenPrice: price invalid");
    //     // result is on 8 decimals 
    //     return uint256(price);
    // }


    // describe("test mint", function () {

    //     beforeEach(async function () {
    //         HodlInstance = await Hodl.new();
    //     });

    //     xit("should not mint (not owner)", async () => {
    //         HodlInstance = await Hodl.new();
    //         await expectRevert(HodlInstance.mint(owner, 100, {from: user1}), 'Ownable: caller is not the owner');
    //     });
    //     xit("should mint", async () => {
    //         HodlInstance = await Hodl.new();
    //         expectedAmountnew = BN(10).pow(new BN(18))
    //         await HodlInstance.mint(owner, 1, {from: owner});
    //         expect(await HodlInstance.balanceOf(owner)).to.be.bignumber.equal(expectedAmountnew);
    //     });
    // });


    // describe("test Pair creation", function () {

    //     beforeEach(async function () {
    //         HodlInstance = await Hodl.new();
    //         HodlUpRewardManagerInstance = await HodlUpRewardManager.new(HodlInstance.address, 600);
    //         HodlUpHubInstance = await HodlUpHub.new(uniswapRouterAddress,uniswapRouterAddress, 50, 20, {from:owner});
    //     });

    //     xit("should not create Pair (not owner)", async () => {
    //         await expectRevert(HodlUpHubInstance.addPair(USDC_ADDRESS, SAND_ADDRESS, true, {from: user1}), 'Ownable: caller is not the owner');
    //     });

    //     xit("should not create Pair (Non existing Input Token)", async () => {
    //         await expectRevert(HodlUpHubInstance.addPair(uniswapRouterAddress, SAND_ADDRESS, true, {from: owner}), 'Input Token is not available. No Supply');
    //     });

    //     xit("should not create Pair (Non existing Output Token)", async () => {
    //         await expectRevert(HodlUpHubInstance.addPair(USDC_ADDRESS, uniswapRouterAddress, true, {from: owner}), 'Output Token is not available. No Supply');
    //     });

    //     xit("should not create Pair (Non existing Output Token)", async () => {
    //         await expectRevert(HodlUpHubInstance.addPair(USDC_ADDRESS, uniswapRouterAddress, true, {from: owner}), 'Output Token is not available. No Supply');
    //     });

    //     xit("should create Pair (event)", async () => {            
    //         //expect(await HodlUpHubInstance.pairsAvailable.length).to.be.bignumber.equal(new BN(0));
    //         expectEvent(await HodlUpHubInstance.addPair(USDC_ADDRESS, SAND_ADDRESS, true, {from: owner}) , "PairAdded", {token_from: USDC_ADDRESS, token_to: SAND_ADDRESS});
    //     });

    //     xit("should create Pair", async () => {            
    //         await HodlUpHubInstance.addPair(USDC_ADDRESS, SAND_ADDRESS, true, {from: owner});
    //         const pair = await HodlUpHubInstance.pairsAvailable(0);
    //         await expect(pair.token_from).to.equal(USDC_ADDRESS);
    //         await expect(pair.token_to).to.equal(SAND_ADDRESS);
    //         await expect(pair.active).to.be.true;
    //     });

    //     xit("should not create Pair (already exists)", async () => {            
    //         await HodlUpHubInstance.addPair(USDC_ADDRESS, SAND_ADDRESS, true, {from: owner});
    //         await expectRevert(HodlUpHubInstance.addPair(USDC_ADDRESS, SAND_ADDRESS, true, {from: owner}), 'Pair already exists');
    //     });
    // });



});