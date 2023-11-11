const Hodl = artifacts.require("./Hodl.sol");
const { BN, expectRevert, expectEvent, time } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const ERC20TransferABI = require ("../../client/src/contracts/IERC20.json");

contract('Hodl', accounts => {
    const owner = accounts[0];
    const user1 = accounts[1];
    const user2 = accounts[2];

    let HodlInstance;

    describe("test constructor", function () {
        it("should be initialize contract states", async () => {
            HodlInstance = await Hodl.new();
            expect(await HodlInstance.name.call()).to.equal("Hodl");
            expect(await HodlInstance.symbol.call()).to.equal("HODL");
        });
    });

    describe("test mint", function () {

        beforeEach(async function () {
            HodlInstance = await Hodl.new();
        });

        it("should not mint (not owner)", async () => {
            HodlInstance = await Hodl.new();
            await expectRevert(HodlInstance.mint(owner, 100, {from: user1}), 'Ownable: caller is not the owner');
        });
        it("should mint", async () => {
            HodlInstance = await Hodl.new();
            expectedAmountnew = BN(10).pow(new BN(18))
            await HodlInstance.mint(owner, 1, {from: owner});
            expect(await HodlInstance.balanceOf(owner)).to.be.bignumber.equal(expectedAmountnew);
        });
    });


});