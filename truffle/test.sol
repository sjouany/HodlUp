// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract DCATokenExchange {
    address public tokenA;
    address public tokenB;
    address public uniswapRouter;
    uint public amountBought;
    uint public interval;
    uint public lastPurchaseTime;
    uint public totalPurchases;

    constructor(
        address _tokenA,
        address _tokenB,
        address _uniswapRouter,
        uint _interval
    ) {
        tokenA = _tokenA;
        tokenB = _tokenB;
        uniswapRouter = _uniswapRouter;
        interval = _interval;
        lastPurchaseTime = block.timestamp;
    }

    function purchase() external {
        require(block.timestamp >= lastPurchaseTime + interval, "Purchase not yet available");
        uint tokenABalance = IERC20(tokenA).balanceOf(address(this));
        require(tokenABalance > 0, "No token A balance available");
        uint[] memory amounts = IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(
            tokenABalance,
            0,
            getPathForTokenAtoB(),
            address(this),
            block.timestamp + 1800
        );
        amountBought += amounts[1];
        lastPurchaseTime = block.timestamp;
        totalPurchases++;
    }

    function getPathForTokenAtoB() private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
        return path;
    }

    function withdraw() external {
        IERC20(tokenB).transfer(msg.sender, IERC20(tokenB).balanceOf(address(this)));
    }
}