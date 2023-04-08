const HodlUpHub = artifacts.require("./HodlUpHub.sol");
const HodlUpRewardManager = artifacts.require("./HodlUpRewardsManager.sol");
const Hodl = artifacts.require("./Hodl.sol");
const { BN, expectRevert, expectEvent, time } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const ERC20TransferABI = require ("../../client/src/contracts/IERC20.json");

contract('HodlUpHub', accounts => {
    const owner = accounts[0];
    const user1 = accounts[1];
    const user2 = accounts[2];

    let HodlUpHubInstance;
    let HodlUpRewardManagerInstance;
    let HodlInstance;

    const USDC_ADDRESS = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174";
    const SAND_ADDRESS = "0xBbba073C31bF03b8ACf7c28EF0738DeCF3695683";
    const usdcToken = new web3.eth.Contract(ERC20TransferABI.abi, USDC_ADDRESS);
    const sandToken = new web3.eth.Contract(ERC20TransferABI.abi, SAND_ADDRESS);
    const whaleAddress = "0xe7804c37c13166fF0b37F5aE0BB07A3aEbb6e245";
    const uniswapRouterAddress = "0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff";

    describe("test constructor", function () {
        xit("should be initialize contract states", async () => {
            HodlInstance = await Hodl.new();
            HodlUpRewardManagerInstance = await HodlUpRewardManager.new(HodlInstance.address, 600);
            HodlUpHubInstance = await HodlUpHub.new(uniswapRouterAddress,uniswapRouterAddress, 50, 20, {from:owner});
            expect(await HodlUpHubInstance.depositFee.call()).to.be.bignumber.equal(new BN(50));
            expect(await HodlUpHubInstance.swapFee.call()).to.be.bignumber.equal(new BN(20));
            expect(await HodlUpHubInstance.uniswapRouter.call()).to.equal(uniswapRouterAddress);
        });
    });

    describe("test Pair creation", function () {

        beforeEach(async function () {
            HodlInstance = await Hodl.new();
            HodlUpRewardManagerInstance = await HodlUpRewardManager.new(HodlInstance.address, 600);
            HodlUpHubInstance = await HodlUpHub.new(uniswapRouterAddress,uniswapRouterAddress, 50, 20, {from:owner});
        });

        xit("should not create Pair (not owner)", async () => {
            await expectRevert(HodlUpHubInstance.addPair(USDC_ADDRESS, SAND_ADDRESS, true, {from: user1}), 'Ownable: caller is not the owner');
        });

        xit("should not create Pair (Non existing Input Token)", async () => {
            await expectRevert(HodlUpHubInstance.addPair(uniswapRouterAddress, SAND_ADDRESS, true, {from: owner}), 'Input Token is not available. No Supply');
        });

        xit("should not create Pair (Non existing Output Token)", async () => {
            await expectRevert(HodlUpHubInstance.addPair(USDC_ADDRESS, uniswapRouterAddress, true, {from: owner}), 'Output Token is not available. No Supply');
        });

        xit("should not create Pair (Non existing Output Token)", async () => {
            await expectRevert(HodlUpHubInstance.addPair(USDC_ADDRESS, uniswapRouterAddress, true, {from: owner}), 'Output Token is not available. No Supply');
        });

        xit("should create Pair (event)", async () => {            
            //expect(await HodlUpHubInstance.pairsAvailable.length).to.be.bignumber.equal(new BN(0));
            expectEvent(await HodlUpHubInstance.addPair(USDC_ADDRESS, SAND_ADDRESS, true, {from: owner}) , "PairAdded", {token_from: USDC_ADDRESS, token_to: SAND_ADDRESS});
        });

        xit("should create Pair", async () => {            
            await HodlUpHubInstance.addPair(USDC_ADDRESS, SAND_ADDRESS, true, {from: owner});
            const pair = await HodlUpHubInstance.pairsAvailable(0);
            await expect(pair.token_from).to.equal(USDC_ADDRESS);
            await expect(pair.token_to).to.equal(SAND_ADDRESS);
            await expect(pair.active).to.be.true;
        });

        xit("should not create Pair (already exists)", async () => {            
            await HodlUpHubInstance.addPair(USDC_ADDRESS, SAND_ADDRESS, true, {from: owner});
            await expectRevert(HodlUpHubInstance.addPair(USDC_ADDRESS, SAND_ADDRESS, true, {from: owner}), 'Pair already exists');
        });
    });

    describe("test Interval creation", function () {

        beforeEach(async function () {
            HodlInstance = await Hodl.new();
            HodlUpRewardManagerInstance = await HodlUpRewardManager.new(HodlInstance.address, 600);
            HodlUpHubInstance = await HodlUpHub.new(uniswapRouterAddress,uniswapRouterAddress, 50, 20, {from:owner});
        });

        xit("should not create Interval (not owner)", async () => {
            await expectRevert(HodlUpHubInstance.addInterval(1, {from: user1}), 'Ownable: caller is not the owner');
        });

        xit("should create Interval", async () => {            
            await HodlUpHubInstance.addInterval(1, {from: owner});
            const interval = await HodlUpHubInstance.intervalsAvailable(0);
            await expect(interval).to.be.bignumber.equal(new BN(1));
        });

        xit("should create Interval (event)", async () => {
            expectEvent(await HodlUpHubInstance.addInterval(1, {from: owner}) , "IntervalAdded", {interval: new BN(1)});
        });
    });

    describe("test Position Creation", function () {

        beforeEach(async function () {
            HodlInstance = await Hodl.new();
            HodlUpRewardManagerInstance = await HodlUpRewardManager.new(HodlInstance.address, 600);
            HodlUpHubInstance = await HodlUpHub.new(uniswapRouterAddress,uniswapRouterAddress, 50, 20, {from:owner});
            await HodlUpHubInstance.addPair(USDC_ADDRESS, SAND_ADDRESS, true, {from: owner});
            await HodlUpHubInstance.addInterval(1, {from: owner});
            const whaleUsdcBalance = await usdcToken.methods.balanceOf(whaleAddress).call();
            const whaleSandBalance = await sandToken.methods.balanceOf(whaleAddress).call();
            const txReceiptUsdc = await usdcToken.methods.transfer(user1, whaleUsdcBalance).send({ from: whaleAddress });
            const user1UsdcBalance =  await usdcToken.methods.balanceOf(user1).call();
            const user1SandBalance =  await sandToken.methods.balanceOf(user1).call();
            const txApproveUsdc = await usdcToken.methods.approve(HodlUpHubInstance.address, user1UsdcBalance).send({ from: user1 });
            const txApproveSand = await sandToken.methods.approve(HodlUpHubInstance.address, user1SandBalance).send({ from: user1 });
        });

        xit("should not create Position (name empty)", async () => {
            const pair = await HodlUpHubInstance.pairsAvailable(0);
            const interval = await HodlUpHubInstance.intervalsAvailable(0);
            await expectRevert(HodlUpHubInstance.createPosition("", pair, 1000000000, interval, 50000000, 0, false, {from: user1}), 'name must be set');
        });

        xit("should not create Position (pair not available)", async () => {
            const pair = await HodlUpHubInstance.pairsAvailable(0);
            pair.token_from = pair.token_to;
            const interval = await HodlUpHubInstance.intervalsAvailable(0);
            await expectRevert(HodlUpHubInstance.createPosition("test", pair, 1000000000, interval, 50000000, 0, false, {from: user1}), "pair not available");
        });

        
        xit("should not create Position (interval not available)", async () => {
            const pair = await HodlUpHubInstance.pairsAvailable(0);
            await expectRevert(HodlUpHubInstance.createPosition("test", pair, 1000000000, 2, 50000000, 0, false, {from: user1}), 'this interval is not allowed');
        });

        xit("should not create Position (no amount for DCA)", async () => {
            const pair = await HodlUpHubInstance.pairsAvailable(0);
            const interval = await HodlUpHubInstance.intervalsAvailable(0);
            await expectRevert(HodlUpHubInstance.createPosition("test", pair, 0, interval, 50000000, 0, false, {from: user1}), 'No amount set for DCA');
        });

        xit("should not create Position (amount per swap and number of iterations)", async () => {
            const pair = await HodlUpHubInstance.pairsAvailable(0);
            const interval = await HodlUpHubInstance.intervalsAvailable(0);
            await expectRevert(HodlUpHubInstance.createPosition("test", pair, 1000000000, interval, 50000000, 2, false, {from: user1}), 'Set only amount per swap or number of iterations');
            await expectRevert(HodlUpHubInstance.createPosition("test", pair, 1000000000, interval, 0, 0, false, {from: user1}), 'Set only amount per swap or number of iterations');
        });

        xit("should create Position (without stacking and number iteration set)", async () => {
            const nbIterations = 2;
            const totalToSwap = 1000000000;
            const amountPerSwap = 0;
            const pair = await HodlUpHubInstance.pairsAvailable(0);
            const interval = await HodlUpHubInstance.intervalsAvailable(0);
            await HodlUpHubInstance.createPosition("test", pair, totalToSwap, interval, amountPerSwap, nbIterations, false, {from: user1});
            const position = await HodlUpHubInstance.getPosition(0, {from: user1});
            await expect(position.name).to.equal('test');
            await expect(position.pair.token_from).to.equal(USDC_ADDRESS);
            await expect(position.pair.token_to).to.equal(SAND_ADDRESS);
            await expect(position.pair.active).to.be.true;
            await expect(position.totalAmountToSwap).to.be.bignumber.equal(new BN(totalToSwap * 0.995));
            await expect(position.interval).to.be.bignumber.equal(new BN(1));
            await expect(position.dcaIterations).to.be.bignumber.equal(new BN(nbIterations));
            await expect(position.amountPerSwap).to.be.bignumber.equal(new BN(totalToSwap * 0.995 / nbIterations));
            await expect(position.lastPurchaseTimestamp).to.be.bignumber.equal(new BN(position.createdTimestamp));
            await expect(position.SwappedFromBalance).to.be.bignumber.equal(new BN(0));
            await expect(position.SwappedToBalance).to.be.bignumber.equal(new BN(0));
            await expect(position.status).to.be.bignumber.equal(new BN(0));
            await expect(position.recipient).to.equal(user1);
            await expect(position.stacking).to.be.false;
            await expect(position.mode).to.be.bignumber.equal(new BN(0));
        });

        xit("should create Position (without stacking and amount per swap set)", async () => {
            const nbIterations = 0;
            const totalToSwap = 1000000000;
            const amountPerSwap = 500000;
            const pair = await HodlUpHubInstance.pairsAvailable(0);
            const interval = await HodlUpHubInstance.intervalsAvailable(0);
            await HodlUpHubInstance.createPosition("test", pair, totalToSwap, interval, amountPerSwap, nbIterations, false, {from: user1});
            const position = await HodlUpHubInstance.getPosition(0, {from: user1});
            await expect(position.name).to.equal('test');
            await expect(position.pair.token_from).to.equal(USDC_ADDRESS);
            await expect(position.pair.token_to).to.equal(SAND_ADDRESS);
            await expect(position.pair.active).to.be.true;
            await expect(position.totalAmountToSwap).to.be.bignumber.equal(new BN(totalToSwap * 0.995));
            await expect(position.interval).to.be.bignumber.equal(new BN(1));
            await expect(position.dcaIterations).to.be.bignumber.equal(new BN(nbIterations));
            await expect(position.amountPerSwap).to.be.bignumber.equal(new BN(amountPerSwap));
            await expect(position.lastPurchaseTimestamp).to.be.bignumber.equal(new BN(position.createdTimestamp));
            await expect(position.SwappedFromBalance).to.be.bignumber.equal(new BN(0));
            await expect(position.SwappedToBalance).to.be.bignumber.equal(new BN(0));
            await expect(position.status).to.be.bignumber.equal(new BN(0));
            await expect(position.recipient).to.equal(user1);
            await expect(position.stacking).to.be.false;
            await expect(position.mode).to.be.bignumber.equal(new BN(1));
        });

        xit("should create Position (with stacking)", async () => {
            const nbIterations = 2;
            const totalToSwap = 1000000000;
            const amountPerSwap = 0;
            const pair = await HodlUpHubInstance.pairsAvailable(0);
            const interval = await HodlUpHubInstance.intervalsAvailable(0);
            await HodlUpHubInstance.createPosition("test", pair, totalToSwap, interval, amountPerSwap, nbIterations, true, {from: user1});
            const position = await HodlUpHubInstance.getPosition(0, {from: user1});
            await expect(position.name).to.equal('test');
            await expect(position.pair.token_from).to.equal(USDC_ADDRESS);
            await expect(position.pair.token_to).to.equal(SAND_ADDRESS);
            await expect(position.pair.active).to.be.true;
            await expect(position.totalAmountToSwap).to.be.bignumber.equal(new BN(totalToSwap * 0.995));
            await expect(position.interval).to.be.bignumber.equal(new BN(1));
            await expect(position.dcaIterations).to.be.bignumber.equal(new BN(nbIterations));
            await expect(position.amountPerSwap).to.be.bignumber.equal(new BN(totalToSwap * 0.995 / nbIterations));
            await expect(position.lastPurchaseTimestamp).to.be.bignumber.equal(new BN(position.createdTimestamp));
            await expect(position.SwappedFromBalance).to.be.bignumber.equal(new BN(0));
            await expect(position.SwappedToBalance).to.be.bignumber.equal(new BN(0));
            await expect(position.status).to.be.bignumber.equal(new BN(0));
            await expect(position.recipient).to.equal(user1);
            await expect(position.stacking).to.be.true;
            await expect(position.mode).to.be.bignumber.equal(new BN(0));
        });

        xit("should create Position (event)", async () => {
            const nbIterations = 2;
            const totalToSwap = 1000000000;
            const amountPerSwap = 0;
            const pair = await HodlUpHubInstance.pairsAvailable(0);
            const interval = await HodlUpHubInstance.intervalsAvailable(0);
            expectEvent(await HodlUpHubInstance.createPosition("test", pair, totalToSwap, interval, amountPerSwap, nbIterations, false, {from: user1}), "PositionCreated", {sender: user1 , id: new BN(0)});
        });

        xit("should create Position (test adding user into users Addresses array)", async () => {
            const nbIterations = 2;
            const totalToSwap = 1000000000;
            const amountPerSwap = 0;
            const pair = await HodlUpHubInstance.pairsAvailable(0);
            const interval = await HodlUpHubInstance.intervalsAvailable(0);
            await HodlUpHubInstance.createPosition("test", pair, totalToSwap, interval, amountPerSwap, nbIterations, false, {from: user1});
            const adresse = await HodlUpHubInstance.userAddresses(0);
            await expect(adresse).to.equal(user1);
        });

    });

    describe("test DCA", function () {
        beforeEach(async function () {
            HodlInstance = await Hodl.new();
            HodlUpRewardManagerInstance = await HodlUpRewardManager.new(HodlInstance.address, 600);
            HodlUpHubInstance = await HodlUpHub.new(uniswapRouterAddress,uniswapRouterAddress, 50, 20, {from:owner});
            await HodlUpHubInstance.addPair(USDC_ADDRESS, SAND_ADDRESS, true, {from: owner});
            await HodlUpHubInstance.addInterval(1, {from: owner});

            const whaleUsdcBalance = await usdcToken.methods.balanceOf(whaleAddress).call();
            const whaleSandBalance = await sandToken.methods.balanceOf(whaleAddress).call();
            const txReceiptUsdc = await usdcToken.methods.transfer(user1, whaleUsdcBalance).send({ from: whaleAddress });
            const user1UsdcBalance =  await usdcToken.methods.balanceOf(user1).call();
            const user1SandBalance =  await sandToken.methods.balanceOf(user1).call();
            const txApproveUsdc = await usdcToken.methods.approve(HodlUpHubInstance.address, user1UsdcBalance).send({ from: user1 });
            const txApproveSand = await sandToken.methods.approve(HodlUpHubInstance.address, user1SandBalance).send({ from: user1 });
        });

        xit("should execute swap without stacking", async () => {
            const nbIterations = 2;
            const totalToSwap = 1000000000;
            const amountPerSwap = 0;
            const pair = await HodlUpHubInstance.pairsAvailable(0);
            const interval = await HodlUpHubInstance.intervalsAvailable(0);
            await HodlUpHubInstance.createPosition("test", pair, totalToSwap, interval, amountPerSwap, nbIterations, false, {from: user1});
            await time.increase(3600);
            const user1SandBalanceBefore =  await sandToken.methods.balanceOf(user1).call();
            const contractSandBalanceBefore =  await sandToken.methods.balanceOf(HodlUpHubInstance.address).call();
            await HodlUpHubInstance.executeSwap({from: owner});
            const user1SandBalanceAfter =  await sandToken.methods.balanceOf(user1).call();
            const contractSandBalanceAfter =  await sandToken.methods.balanceOf(HodlUpHubInstance.address).call();
            const position = await HodlUpHubInstance.getPosition(0, {from: user1});
            await expect(position.totalAmountToSwap).to.be.bignumber.equal(new BN(totalToSwap * 0.995));
            await expect(position.dcaIterations).to.be.bignumber.equal(new BN(nbIterations-1));
            await expect(position.amountPerSwap).to.be.bignumber.equal(new BN(totalToSwap * 0.995 / nbIterations));
            await expect(position.lastPurchaseTimestamp).to.be.bignumber.greaterThan(new BN(position.createdTimestamp));
            await expect(position.SwappedFromBalance).to.be.bignumber.greaterThan(new BN(0));
            await expect(position.SwappedToBalance).to.be.bignumber.greaterThan(new BN(0));
            await expect(position.status).to.be.bignumber.equal(new BN(0));
            await expect(position.mode).to.be.bignumber.equal(new BN(0));
            await expect(user1SandBalanceAfter).to.be.bignumber.greaterThan(new BN(user1SandBalanceBefore));
            await expect(contractSandBalanceBefore).to.be.bignumber.equal(new BN(contractSandBalanceAfter));
        });

        xit("should execute swap without stacking (event)", async () => {
            const nbIterations = 2;
            const totalToSwap = 1000000000;
            const amountPerSwap = 0;
            const pair = await HodlUpHubInstance.pairsAvailable(0);
            const interval = await HodlUpHubInstance.intervalsAvailable(0);
            await HodlUpHubInstance.createPosition("test", pair, totalToSwap, interval, amountPerSwap, nbIterations, false, {from: user1});
            await time.increase(3600);
            expectEvent(await HodlUpHubInstance.executeSwap({from: owner}) , "DCAExecuted", {user: user1, positionId: new BN(0), token_from: USDC_ADDRESS, token_to: SAND_ADDRESS});
        });

        xit("should execute swap without stacking and with no sufficient funds", async () => {
            const nbIterations = 0;
            const totalToSwap = 1000000000;
            const amountPerSwap = 400000000;
            const pair = await HodlUpHubInstance.pairsAvailable(0);
            const interval = await HodlUpHubInstance.intervalsAvailable(0);
            await HodlUpHubInstance.createPosition("test", pair, totalToSwap, interval, amountPerSwap, nbIterations, false, {from: user1});
            await time.increase(3600);
            await HodlUpHubInstance.executeSwap({from: owner});
            await time.increase(3600);
            await HodlUpHubInstance.executeSwap({from: owner});
            await time.increase(3600);
            await HodlUpHubInstance.executeSwap({from: owner});
            const position = await HodlUpHubInstance.getPosition(0, {from: user1});            
            await expect(position.totalAmountToSwap).to.be.bignumber.equal(new BN(totalToSwap * 0.995));
            await expect(position.amountPerSwap).to.be.bignumber.equal(new BN(amountPerSwap));
            await expect(position.lastPurchaseTimestamp).to.be.bignumber.greaterThan(new BN(position.createdTimestamp));
            await expect(position.SwappedFromBalance).to.be.bignumber.equal(new BN(amountPerSwap * 2));
            await expect(position.status).to.be.bignumber.equal(new BN(1));
            await expect(position.mode).to.be.bignumber.equal(new BN(1));
        });

        xit("should execute swap with stacking", async () => {
            const nbIterations = 2;
            const totalToSwap = 1000000000;
            const amountPerSwap = 0;
            const pair = await HodlUpHubInstance.pairsAvailable(0);
            const interval = await HodlUpHubInstance.intervalsAvailable(0);
            await HodlUpHubInstance.createPosition("test", pair, totalToSwap, interval, amountPerSwap, nbIterations, true, {from: user1});
            await time.increase(3600);
            const user1SandBalanceBefore =  await sandToken.methods.balanceOf(user1).call();
            const contractSandBalanceBefore =  await sandToken.methods.balanceOf(HodlUpHubInstance.address).call();
            await HodlUpHubInstance.executeSwap({from: owner});
            const user1SandBalanceAfter =  await sandToken.methods.balanceOf(user1).call();
            const contractSandBalanceAfter =  await sandToken.methods.balanceOf(HodlUpHubInstance.address).call();
            const position = await HodlUpHubInstance.getPosition(0, {from: user1});
            await expect(position.totalAmountToSwap).to.be.bignumber.equal(new BN(totalToSwap * 0.995));
            await expect(position.dcaIterations).to.be.bignumber.equal(new BN(nbIterations-1));
            await expect(position.amountPerSwap).to.be.bignumber.equal(new BN(totalToSwap * 0.995 / nbIterations));
            await expect(position.lastPurchaseTimestamp).to.be.bignumber.greaterThan(new BN(position.createdTimestamp));
            await expect(position.SwappedFromBalance).to.be.bignumber.greaterThan(new BN(0));
            await expect(position.SwappedToBalance).to.be.bignumber.greaterThan(new BN(0));
            await expect(position.status).to.be.bignumber.equal(new BN(0));
            await expect(position.mode).to.be.bignumber.equal(new BN(0));
            await expect(user1SandBalanceAfter).to.be.bignumber.equal(new BN(user1SandBalanceBefore));
            await expect(contractSandBalanceAfter).to.be.bignumber.greaterThan(new BN(contractSandBalanceBefore));
        });

        xit("should execute swap with stacking (event)", async () => {
            const nbIterations = 2;
            const totalToSwap = 1000000000;
            const amountPerSwap = 0;
            const pair = await HodlUpHubInstance.pairsAvailable(0);
            const interval = await HodlUpHubInstance.intervalsAvailable(0);
            await HodlUpHubInstance.createPosition("test", pair, totalToSwap, interval, amountPerSwap, nbIterations, true, {from: user1});
            await time.increase(3600);
            expectEvent(await HodlUpHubInstance.executeSwap({from: owner}) , "DCAExecuted", {user: user1, positionId: new BN(0), token_from: USDC_ADDRESS, token_to: SAND_ADDRESS});
        });

    });
    describe("Close Position", function () {

        beforeEach(async function () {
            HodlInstance = await Hodl.new();
            HodlUpRewardManagerInstance = await HodlUpRewardManager.new(HodlInstance.address, 600);
            HodlUpHubInstance = await HodlUpHub.new(uniswapRouterAddress,uniswapRouterAddress, 50, 20, {from:owner});            
            await HodlUpHubInstance.addPair(USDC_ADDRESS, SAND_ADDRESS, true, {from: owner});
            await HodlUpHubInstance.addInterval(1, {from: owner});
            const nbIterations = 2;
            const totalToSwap = 1000000000;
            const amountPerSwap = 0;
            const whaleUsdcBalance = await usdcToken.methods.balanceOf(whaleAddress).call();
            const whaleSandBalance = await sandToken.methods.balanceOf(whaleAddress).call();
            const txReceiptUsdc = await usdcToken.methods.transfer(user1, whaleUsdcBalance).send({ from: whaleAddress });
            const user1UsdcBalance =  await usdcToken.methods.balanceOf(user1).call();
            const user1SandBalance =  await sandToken.methods.balanceOf(user1).call();
            const txApproveUsdc = await usdcToken.methods.approve(HodlUpHubInstance.address, user1UsdcBalance).send({ from: user1 });
            const txApproveSand = await sandToken.methods.approve(HodlUpHubInstance.address, user1SandBalance).send({ from: user1 });
            const pair = await HodlUpHubInstance.pairsAvailable(0);
            const interval = await HodlUpHubInstance.intervalsAvailable(0);
            await HodlUpHubInstance.createPosition("test", pair, totalToSwap, interval, amountPerSwap, nbIterations, true, {from: user1});
            await time.increase(3600);
            await HodlUpHubInstance.executeSwap({from: owner});
        });

        xit("should execute swap with stacking (event)", async () => {
            const user1SandBalanceBefore = await sandToken.methods.balanceOf(user1).call();
            const position = await HodlUpHubInstance.getPosition(0, {from: user1});
            await HodlUpHubInstance.closePosition(0, {from: user1});
            const user1SandBalanceAfter = await sandToken.methods.balanceOf(user1).call();
            const swapped = new BN(position.SwappedToBalance);
            const before = new BN(user1SandBalanceBefore);
            const after = new BN(user1SandBalanceAfter);
            const result = before.add(swapped);
            expect(after).to.be.bignumber.equal(result);
        });
    });


    // function createPosition(string calldata _name, Pair calldata _pair, uint _totalAmountToSwap, uint _interval, uint _amountPerSwap, uint _dcaIterations, bool _stacking) external {
    //     require(bytes(_name).length > 0, "name must be set"); 
    //     require(!_positionExists(msg.sender, _name, _pair), "Position is already existing");
    //     require(_pairExists(_pair), "pair not available");
    //     require(_intervalExists(_interval), "this interval is not allowed");
    //     require(_totalAmountToSwap > 0, "No amount set for DCA");
    //     require( (_amountPerSwap == 0 && _dcaIterations != 0) || (_amountPerSwap != 0 && _dcaIterations == 0), "Set only amount per swap or number of iterations" );

    //     uint totalToSwapAfterFees = _totalAmountToSwap - (_totalAmountToSwap * depositFee / 10000);
    //     uint amountPerSwap = _amountPerSwap > 0 ? _amountPerSwap : ((totalToSwapAfterFees * 10000) / _dcaIterations) / 10000;

    //     require (amountPerSwap > 0, "amount per swap cannot be 0");

    //     SafeERC20.safeTransferFrom(_pair.token_from, msg.sender, address(this), _totalAmountToSwap);   
    //             if (!_userExists(msg.sender)){
    //         userAddresses.push(msg.sender);
    //     }
    //     users[msg.sender].Positions.push(Position(_name, _pair, totalToSwapAfterFees, _interval, _dcaIterations, amountPerSwap, block.timestamp, block.timestamp, 0, 0, 0, Status.Active ,msg.sender, _stacking, _dcaIterations == 0 ? DcaMode.Unlimited : DcaMode.Limited ));
    
    //     emit PositionCreated (msg.sender, users[msg.sender].Positions.length-1, block.timestamp);  
    // }



    // describe("test state ProposalsRegistrationStarted", function () {

    //     beforeEach(async function () {
    //         VotingInstance = await Voting.new({from:owner});
    //         await HodlUpHubInstance.addVoter(voter1);
    //     });

    //     xit("should set ProposalsRegistrationStarted state", async () => {
    //         await VotingInstance.startProposalsRegistering({from: owner})
    //         expect(await VotingInstance.workflowStatus.call()).to.be.bignumber.equal(new BN(1));
    //     });

    //     xit("should not set ProposalsRegistrationStarted state (not Owner)", async () => {
    //         await expectRevert(VotingInstance.startProposalsRegistering({from: voter1}), 'Ownable: caller is not the owner');
    //     });

    //     xit("should not set ProposalsRegistrationStarted state (no compliant previous state)", async () => {
    //         await VotingInstance.startProposalsRegistering({from: owner});
    //         // try to start Proposal registering period already launched
    //         await expectRevert(VotingInstance.startProposalsRegistering({from: owner}), 'Registering proposals cant be started now');
    //     });

    //     xit("should emit event WorkflowStatusChange", async () => {
    //         expectEvent(await VotingInstance.startProposalsRegistering({from: owner}), "WorkflowStatusChange", {previousStatus: new BN(0), newStatus: new BN(1)});
    //     });

    //     xit("should initialize a proposal Genesis", async () => {
    //         await VotingInstance.startProposalsRegistering({from: owner});
    //         const proposal = await VotingInstance.getOneProposal(0, {from: voter1});
    //         expect(proposal.description).to.equal("GENESIS");
    //     });
 
    // });


});