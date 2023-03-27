const HodlUpHub = artifacts.require("./HodlUpHub.sol");
const TokenContract = artifacts.require("@openzeppelin/contracts/token/ERC20/ERC20.sol");

const { BN, expectRevert, expectEvent } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

web3.eth.sendTransaction({
    from: '0xe7804c37c13166fF0b37F5aE0BB07A3aEbb6e245',
    to: '0x2dC55ec5fC4a5D2dDd662f747F3a4f1784F34eEC',
    value: '10'
})


contract('HodlUpHub', accounts => {
    const owner = accounts[0];
    const whale = "0xe7804c37c13166fF0b37F5aE0BB07A3aEbb6e245";
    const voter2 = accounts[2];
    const voter3 = accounts[3];
    const voter_not_registered = accounts[4];

    let HodlUpHubInstance;
    let TokenContractInstance;

    describe("test transferfrom", function () {
        it("test transferfrom", async () => {
            TokenContractInstance
            HodlUpHubInstance = await HodlUpHub.new({from:whale});
            result = await HodlUpHubInstance.initialize();
            console.log(result);
        });
    });



});