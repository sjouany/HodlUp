// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "../node_modules/@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

using SafeERC20 for IERC20;

/**
 * @title HodlUpRewardsManager
 * @dev This contract manages the distribution of rewards in the form of an ERC20 token (HODL) to users who hold specific ERC20 tokens.
 */
contract HodlUpRewardsManager is Ownable {

    // 1 rewardToken (here HODL) is equal to 1 USD
    ERC20 public rewardToken;
    uint public rewardApy;
    mapping(address => uint) balances;
    mapping(address => address) public oracles;
    mapping(address => bool) public authorizedContracts;

    /**
     * @dev Constructor function
     * @param _rewardTokenAddress The address of the reward token (HODL)
     * @param _rewardApy The annual percentage yield (APY) for the reward token
     */
    constructor(address _rewardTokenAddress, uint _rewardApy) {
        rewardToken = ERC20(_rewardTokenAddress);
        rewardApy = _rewardApy;
    }

    /**
     * @dev Internal function to get the daily reward for a specific ERC20 token based on its USD price and the reward APY
     * @param _token The ERC20 token for which to calculate the daily reward
     * @param _amount The amount of the ERC20 token for which to calculate the daily reward
     * @return The daily reward amount in HODL tokens
     */
    function _getDailyRewardWithAPY(ERC20 _token, uint256 _amount) internal view returns (uint256){
        uint amountConverted = (_amount * getUSDPriceFromOracle(address(_token))) / (10 ** (ERC20(_token).decimals() - AggregatorV3Interface(oracles[address(_token)]).decimals()));
        return ((amountConverted * rewardApy) / 10000) / 365;
    }

    /**
     * @dev Set the reward token 
     * @param _token The address of the new reward token
     */
    function setRewardToken(address _token) external onlyOwner {
        rewardToken = ERC20(_token);
    }

    /**
     * @dev Set the reward APY
     * @param _apy The new reward APY
     */
    function setApy(uint _apy) external onlyOwner {
        rewardApy = _apy;
    }    

    function addOracle(address _token, address _oracle) external onlyOwner {
        oracles[_token] = _oracle;
    }

    /**
     * @dev Get the USD price of an ERC20 token from its associated Chainlink oracle
     * @param _token The ERC20 token for which to get the USD price
     * @return The USD price of the ERC20 token
     */
    function getUSDPriceFromOracle(address _token) public view returns (uint256) {
        (, int256 price, , ,) = AggregatorV3Interface(oracles[_token]).latestRoundData();
        require(price > 0, "TokenPrice: price invalid");
        // result is on 8 decimals 
        return uint256(price);
    }

    /**
    * @dev Adds an authorized contract that is allowed to generate rewards for users.
    * Only the contract owner can call this function.
    * @param _contract The address of the authorized contract.
    */
    function addContract(address _contract) external onlyOwner{
        authorizedContracts[_contract] = true;
        emit ContractAdded (_contract);
    }

    /**
    * @dev Generates rewards for a user based on the given amount of tokens and the current APY.
    * Only authorized contracts can call this function.
    * @param _user The address of the user to receive the rewards.
    * @param _token The ERC20 token used to generate the rewards.
    * @param _amount The amount of tokens to generate rewards for.
    */
    function generateRewards(address _user, ERC20 _token, uint _amount) external returns (uint256){
        require (authorizedContracts[msg.sender] == true, "Access not authorized" );
        uint256 rewards = _getDailyRewardWithAPY(_token, _amount);
        balances[_user] += rewards;
        return rewards;
    }

    /**
    * @dev Allows a user to claim their rewards in the specified amount of tokens.
    * The user must have a balance greater than or equal to the amount being claimed.
    * @param _amount The amount of tokens to claim as rewards.
    */
    function claimRewards(uint _amount) external {
        require (balances[msg.sender] - _amount > 0, "No sufficient funds to claim" );
        balances[msg.sender] -=  _amount ;
        SafeERC20.safeTransfer(rewardToken, msg.sender, _amount);
        emit RewardsClaimed (rewardToken, msg.sender, balances[msg.sender], block.timestamp);
    }   

    /**
    * @dev Allows a user to claim all of their available rewards in the reward token.
    * The user must have a balance greater than 0 to claim any rewards.
    */
    function claimAllRewards() external {
        require (balances[msg.sender] > 0, "No sufficient funds to claim" );
        SafeERC20.safeTransfer(rewardToken, msg.sender, balances[msg.sender]);
        emit RewardsClaimed (rewardToken, msg.sender, balances[msg.sender], block.timestamp);
        balances[msg.sender] = 0 ;   
    }   

    /**
    * @dev Emitted when a user claims rewards.
    * @param token The ERC20 token that was claimed.
    * @param user The user who claimed the rewards.
    * @param amount The amount of tokens claimed.
    * @param date The timestamp of the claim.
    */
    event RewardsClaimed (ERC20 token, address user, uint amount, uint date);
    /**
    * @dev Emitted when a new contract is added to the system.
    * @param contractAdded The address of the contract that was added.
    */
    event ContractAdded (address contractAdded);
}

