// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IHodlUpRewardsManager {

    function addContract(address _contract) external;

    function generateRewards(address _user, IERC20 _token, uint _amount) external;

    function claimRewards(uint _amount) external;

    function claimAllRewards() external;

}