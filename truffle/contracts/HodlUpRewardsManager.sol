// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "../node_modules/@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../node_modules/@ganache/console.log/console.sol";
using SafeERC20 for IERC20;

contract HodlUpRewardsManager is Ownable {
// creer un mapping address de token et address de contrat oracle:     mapping(address => address) oracles;
// ajout d'entrée dans mapping
// 
// MATIC   USD   0xab594600376ec9fd91f8e885dadf0ce036862de0
// USDT    USD   0x0a6513e40db6eb1b165753ad52e80663aea50545
// USDC    USD   0xfe4a8cc5b5b2366c1b58bea3858e81843581b2f7
// SAND    USD   0x3d49406edd4d52fb7ffd25485f32e073b529c924
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

