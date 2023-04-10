// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IHodlUpRewardsManager {
    
    function setRewardToken(address _token) external;
    
    function setApy(uint _apy) external;
    
    function addOracle(address _token, address _oracle) external;
    
    function getUSDPriceFromOracle(address _token) external view returns (uint256);
    
    function addContract(address _contract) external;
    
    function generateRewards(address _user, ERC20 _token, uint _amount) external returns (uint256);
    
    function claimRewards(uint _amount) external;
    
    function claimAllRewards() external;
    
    event ContractAdded(address indexed _contract);
    
    event RewardsClaimed(ERC20 indexed _token, address indexed _user, uint256 indexed _balance, uint256 _timestamp);
}
