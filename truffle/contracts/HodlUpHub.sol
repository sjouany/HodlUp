// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import '../node_modules/@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '../node_modules/@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '../node_modules/@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
using SafeERC20 for IERC20;

contract HodlUpHub is Ownable {

// wallet whale MATIC: 0xe7804c37c13166fF0b37F5aE0BB07A3aEbb6e245
// token MATIC 0x0000000000000000000000000000000000001010
// token SAND 0xBbba073C31bF03b8ACf7c28EF0738DeCF3695683
// token USDC 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174
//   ganache --fork https://polygon-mumbai.g.alchemy.com/v2/kN9xDViXa7ZgWWDQgNzzz-I9aIvsxIw3 --seed "grass permit accident owner lock above hello stick divide cigar void language" -i --unlock 0xe7804c37c13166fF0b37F5aE0BB07A3aEbb6e245 --networkId 999
// ganache -f https://polygon-mainnet.g.alchemy.com/v2/E_47dJ_8PBLE24COiPQ1hcE1ZIBVgcps -u 0xe7804c37c13166fF0b37F5aE0BB07A3aEbb6e245 --networkId 999
// ganache -f https://polygon-mainnet.g.alchemy.com/v2/E_47dJ_8PBLE24COiPQ1hcE1ZIBVgcps -u 0xe7804c37c13166fF0b37F5aE0BB07A3aEbb6e245 --networkId 137 -m "grass permit accident owner lock above hello stick divide cigar void language"
//approve sur l'adresse du token ERC20
// voir chainlink pour le prix
//approve sur l'adresse du token ERC20
// voir chainlink pour le prix
// paraswap aggreg mais non dispo sur testnet
//NFT ERC-1155

    Pair[] public pairsAvailable;
    uint256[] public intervalsAvailable;
    //address constant private UNISWAP_V2_FACTORY_ADDRESS = 0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32;
    //address constant private UNISWAP_V2_ROUTER_ADDRESS = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    IUniswapV2Router02 uniswapRouter;
    //IUniswapV2Factory uniswapV2Factory;

    struct User {
        Position[] Positions;
    }

    struct Pair {
        IERC20 token_from;
        IERC20 token_to;
        bool active;
    }

    struct Position {
        string name;
        Pair pair;
        uint totalAmountToSwap;
        uint amountToSwap;
        uint totalSwapped;
        uint averagePrice;
        uint lastPurchaseTimestamp;
        uint interval;
        uint createdTimestamp;
        uint dcaDuration;
        bool pause;
        address recipient;
    }

    mapping(address => User) users;
    address [] userAddresses;


    constructor(address _uniswapRouter) {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        //uniswapV2Factory = IUniswapV2Factory(_uniswapV2Factory);
    }

    function addPair(address _token_from, address _token_to, bool _active) external onlyOwner {
        require(_token_from != _token_to, "Input and Output tokens must be different");
        require(IERC20(_token_from).totalSupply() > 0, "Input Token is not available. No Supply");
        require(IERC20(_token_to).totalSupply() > 0, "Output Token is not available. No Supply");
        require(!_pairExists(Pair(IERC20(_token_from), IERC20(_token_to), true)), "Pair already exists");
        pairsAvailable.push(Pair(IERC20(_token_from), IERC20(_token_to), _active)); 
        emit PairAdded(_token_from, _token_to);
    }

    function addInterval(uint256 _interval) external onlyOwner {
        require(!_intervalExists(_interval), "Interval already added");
        intervalsAvailable.push(_interval); 
        emit IntervalAdded(_interval);
    }

    function createPosition(string calldata _name, Pair calldata _pair, uint _totalAmountToSwap, uint _interval, uint _duration) external {
        require(bytes(_name).length > 0, "name must be set"); 
        require(_pairExists(_pair), "pair not available");
        users[msg.sender].Positions.push(Position(_name, _pair, _totalAmountToSwap, 0, 0, 0, block.timestamp, _interval, block.timestamp, _duration, false, msg.sender));
      
       if (!_userExists(msg.sender)){
            userAddresses.push(msg.sender);
        }
        SafeERC20.safeTransferFrom(_pair.token_from, msg.sender, address(this), _totalAmountToSwap);       
        emit PositionCreated (msg.sender, users[msg.sender].Positions.length-1);  
    }

    function _userExists(address _userAddress) internal view returns (bool) {
        for (uint i = 0; i < userAddresses.length; i++) {
            if (userAddresses[i] == _userAddress) {
                return true;
            }
        }
        return false;
    }

    function executeDCA () external onlyOwner {
        for (uint i = 0; i < pairsAvailable.length; i++) {
            uint totalToSwap = _getTotalToSwap(pairsAvailable[i]);
            _swap(pairsAvailable[i], totalToSwap) ;
        }
    }

    function _pairExists(Pair memory _pair) internal view returns (bool) {
        for (uint i = 0; i < pairsAvailable.length; i++) {
            if (pairsAvailable[i].token_from == _pair.token_from && pairsAvailable[i].token_to == _pair.token_to) {
                return true;
            }
        }
        return false;
    }

    function _intervalExists(uint256 interval) internal view returns (bool) {
        for (uint i = 0; i < intervalsAvailable.length; i++) {
            if (intervalsAvailable[i]==interval) {
                return true;
            }
        }
        return false;
    }

    function _getTotalToSwap(Pair memory _pair) internal view returns(uint256 totalToSwap) {
        for (uint256 i = 0; i < userAddresses.length; i++) {
            Position[] memory positions = users[userAddresses[i]].Positions;
            for (uint256 j = 0; j < positions.length; j++) {
                if (positions[j].pair.token_from == _pair.token_from &&
                    positions[j].pair.token_to == _pair.token_to &&
                    !positions[j].pause &&
                    block.timestamp > positions[j].lastPurchaseTimestamp + positions[j].interval
                ) {
                    totalToSwap += positions[j].amountToSwap;
                }
            }
        }
    }

    function _swap(Pair memory _pair, uint256 _amount) internal returns(uint256 totalSwapped) {
        //require(block.timestamp >= lastSwapTime + swapInterval, "DCAUniswapV2: Not enough time has passed since the last swap");
        uint256 tokenFromAmount = IERC20(_pair.token_from).balanceOf(address(this));
        require(tokenFromAmount > _amount, "Insufficient balance of origin Token");
        IERC20(_pair.token_from).approve(address(uniswapRouter), _amount);

        address pair = IUniswapV2Factory(IUniswapV2Router02(uniswapRouter).factory()).getPair(address(_pair.token_from), address(_pair.token_to));
        if (pair != address(0)){

            address[] memory path = new address[](2);
            path[0] = address(_pair.token_from);
            path[1] = address(_pair.token_to);

            //uint[] memory amounts = uniswapRouter.getAmountsOut(_pair.token_from, path);
             // require(amounts[1] >= montant deduit de chainlink +/- 10%, "Uniswap returned insufficient output amount");
            uint[] memory outputAmounts = uniswapRouter.swapExactTokensForTokens(_amount, 0, path, address(this), block.timestamp + 1800);
            return outputAmounts[1];
        }
        else{
            revert("Pair doesn't exist");
        }
    }

    event PairAdded(address token_from, address token_to);
    event IntervalAdded(uint256 interval);
    event PositionCreated (address sender, uint256 id);

}

