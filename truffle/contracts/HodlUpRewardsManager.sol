// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "../node_modules/@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../node_modules/@ganache/console.log/console.sol";
using SafeERC20 for IERC20;

contract HodlUpRewardsManager is Ownable {

    // 1 rewardToken (here HODL) is equal to 1 USD
    ERC20 rewardToken;
    uint rewardApy;
    mapping(address => uint) balances;
    mapping(address => address) oracles;

    constructor(address _rewardTokenAddress, uint _rewardApy) {
        rewardToken = ERC20(_rewardTokenAddress);
        rewardApy = _rewardApy;
    }

    function getDailyRewardWithAPY(address _token, uint256 _amount) external view returns (uint256){
        uint amountConverted = (_amount * getUSDPriceFromOracle(_token)) / (10 ** (ERC20(_token).decimals() - AggregatorV3Interface(oracles[_token]).decimals()));
        return ((amountConverted * rewardApy) / 10000) / 365;
    }

    function getUSDPriceFromOracle(address _token) public view returns (uint256) {
        (, int256 price, , ,) = AggregatorV3Interface(oracles[_token]).latestRoundData();
        require(price > 0, "TokenPrice: price invalid");
        // result is on 8 decimals 
        return uint256(price);
    }


    // function getPriceFromOracle(address token) external view returns (uint256) {
    //     //AggregatorV3Interface priceFeed = AggregatorV3Interface(oracles[token]);
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(0x3D49406EDd4D52Fb7FFd25485f32E073b529C924);
    //     (, int256 price, , ,) = priceFeed.latestRoundData();
    //     require(price > 0, "TokenPrice: price invalid");
    //     return uint256(price);
    // }

// creer un mapping address de token et address de contrat oracle:     mapping(address => address) oracles;
// ajout d'entrée dans mapping
// 
// MATIC   USD   0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
// USDT    USD   0x0A6513e40db6EB1b165753AD52E80663aeA50545
// USDC    USD   0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7
// SAND    USD   0x3D49406EDd4D52Fb7FFd25485f32E073b529C924
//
// claim Rewards

//   address private oracleAddress;
//     AggregatorV3Interface private priceFeed;
    
//     constructor(address _oracleAddress) {
//         oracleAddress = _oracleAddress;
//         priceFeed = AggregatorV3Interface(oracleAddress);
//     }
    
//     function getTokenPrice(address token) external view returns (uint256) {
//         uint256 price = getPriceFromOracle(token);
//         uint256 decimals = IERC20(token).decimals();
//         uint256 tokenAmount = 10**decimals;
//         return price * tokenAmount;
//     }
    
//     function getPriceFromOracle(address token) internal view returns (uint256) {
//         (, int256 price, , ,) = priceFeed.latestRoundData();
//         require(price > 0, "TokenPrice: price invalid");
//         uint8 decimals = priceFeed.decimals();
//         uint256 usdPrice = uint256(price) * (10**decimals);
//         return usdPrice;
//     }

}

