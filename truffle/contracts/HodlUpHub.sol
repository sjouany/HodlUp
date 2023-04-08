// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import '../node_modules/@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '../node_modules/@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '../node_modules/@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IHodlUpRewardsManager.sol";
//import "../node_modules/@ganache/console.log/console.sol";
using SafeERC20 for IERC20;

/**
 * @title HodlUpHub contract
 * @dev This contract is used for hodling tokens and executing automated periodic swaps.
 */
contract HodlUpHub is Ownable {

    /**
     * @dev Enum representing the available statuses for a position.
     * Active: the position is currently being executed
     * Pause: the position is temporarily paused
     * Closed: the position has been fully executed and cannot be reopened
     * Locked: the position is locked for DCA, meaning that the tokens have been swapped but not transferred to the user
     */
    enum Status {
        Active,
        Pause,
        Closed,
        Locked
    }

    enum DcaMode {
        Limited,
        Unlimited
    }

    Pair[] public pairsAvailable;
    uint256[] public intervalsAvailable;
    IUniswapV2Router02 public uniswapRouter;

    struct User {
        Position[] positions;
        Position[] closedPositions;
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
        uint interval;
        uint dcaIterations;
        uint amountPerSwap;
        uint lastPurchaseTimestamp;
        uint createdTimestamp;
        uint SwappedFromBalance;
        uint SwappedToBalance;  
        Status status;
        address recipient;
        bool stacking;
        DcaMode mode;
    }

    mapping(address => User) users;
    address [] public userAddresses;

    mapping(address => uint) feesBalances;

    // Represents fee percentage taken for deposit. 
    // to avoid rounding errors, we multiply it by 10000. 1% is represented by 100
    uint public depositFee;
    uint public swapFee;

    IHodlUpRewardsManager public rewardsManager;

    constructor(address _uniswapRouter, address _rewardManager, uint _depositFee, uint _swapFee) {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        rewardsManager = IHodlUpRewardsManager(_rewardManager);
        depositFee = _depositFee;
        swapFee = _swapFee;
    }

    function _userExists(address _userAddress) internal view returns (bool) {
        return (users[_userAddress].positions.length > 0);
    }

    // execute DCA for users that has choosen to stack
    function _executeStakedDCA () internal {
        for (uint i = 0; i < pairsAvailable.length; i++) {
            uint totalToSwap = _getTotalToSwap(pairsAvailable[i]);
            uint totalToSwapAfterFees = totalToSwap - (totalToSwap * swapFee / 10000);
            uint totalSwapped = _swap(pairsAvailable[i], totalToSwapAfterFees, address(this)) ;
            for (uint256 j = 0; j < userAddresses.length; j++) {
                Position[] memory positions = users[userAddresses[j]].positions;
                for (uint256 k = 0; k < positions.length; k++) {
                    if (positions[k].status == Status.Locked &&
                        positions[k].stacking == true &&
                        block.timestamp > positions[k].lastPurchaseTimestamp + positions[k].interval
                    ) {
                        if (positions[k].amountPerSwap > (positions[k].totalAmountToSwap - positions[k].SwappedFromBalance)){
                            users[userAddresses[j]].positions[k].status = Status.Pause;
                            emit PositionStatusChanged (userAddresses[j], k, Status.Pause, block.timestamp);  
                        }
                        else{
                            uint amountSwapped = ( ( (positions[k].amountPerSwap * 10000) / totalToSwap ) * totalSwapped) / 10000;
                            if (positions[k].mode == DcaMode.Limited){
                                users[userAddresses[j]].positions[k].dcaIterations = positions[k].dcaIterations - 1 ;
                            }
                            users[userAddresses[j]].positions[k].SwappedFromBalance = positions[k].SwappedFromBalance + positions[k].amountPerSwap;
                            users[userAddresses[j]].positions[k].SwappedToBalance = positions[k].SwappedToBalance + amountSwapped;
                            users[userAddresses[j]].positions[k].status = Status.Active;
                            users[userAddresses[j]].positions[k].lastPurchaseTimestamp = block.timestamp;
                            emit DCAExecuted (userAddresses[j], k, address(positions[k].pair.token_from), address(positions[k].pair.token_to), positions[k].amountPerSwap, amountSwapped, block.timestamp);
                        }
                     }
                }
            }
            //emit DCAExecuted (userAddresses[i], j, address(positions[j].pair.token_from), address(positions[j].pair.token_to), positions[j].amountPerSwap);
        }
    }

    // execute DCA for users that want to get back directly to their wallet
    function _executeIndividualDCA () internal {

        for (uint256 i = 0; i < userAddresses.length; i++) {
            Position[] memory positions = users[userAddresses[i]].positions;
            for (uint256 j = 0; j < positions.length; j++) {
                if (positions[j].status == Status.Active &&
                    positions[j].stacking == false &&
                    block.timestamp > (positions[j].lastPurchaseTimestamp + positions[j].interval)
                ) {
                    if (positions[j].amountPerSwap > (positions[j].totalAmountToSwap - positions[j].SwappedFromBalance)){
                        users[userAddresses[i]].positions[j].status = Status.Pause;
                        emit PositionStatusChanged (userAddresses[i], j, Status.Pause, block.timestamp);  
                    }
                    else{
                        users[userAddresses[i]].positions[j].status = Status.Locked;
                        uint amoutPerSwapAfterFees =  positions[j].amountPerSwap - (positions[j].amountPerSwap * swapFee / 10000);
                        uint resultSwap = _swap( positions[j].pair, amoutPerSwapAfterFees, positions[j].recipient) ;
                        if (positions[j].mode == DcaMode.Limited){
                            users[userAddresses[i]].positions[j].dcaIterations = positions[j].dcaIterations - 1 ;
                        }
                        users[userAddresses[i]].positions[j].SwappedToBalance = positions[j].SwappedToBalance + resultSwap;
                        users[userAddresses[i]].positions[j].SwappedFromBalance = positions[j].SwappedFromBalance + positions[j].amountPerSwap;
                        users[userAddresses[i]].positions[j].status = Status.Active;
                        users[userAddresses[i]].positions[j].lastPurchaseTimestamp = block.timestamp;
                        emit DCAExecuted (userAddresses[i], j, address(positions[j].pair.token_from), address(positions[j].pair.token_to), positions[j].amountPerSwap, resultSwap, block.timestamp);
                    }
                }
            }
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

    function _getTotalToSwap(Pair memory _pair) internal returns(uint256) {
        uint totalToSwap;
        for (uint256 i = 0; i < userAddresses.length; i++) {
            Position[] memory positions = users[userAddresses[i]].positions;
            for (uint256 j = 0; j < positions.length; j++) {
                if (positions[j].pair.token_from == _pair.token_from &&
                    positions[j].pair.token_to == _pair.token_to &&
                    positions[j].status == Status.Active &&
                    positions[j].stacking == true &&
                    block.timestamp > positions[j].lastPurchaseTimestamp + positions[j].interval
                ) {                 
                    totalToSwap +=  positions[j].amountPerSwap;
                    users[userAddresses[i]].positions[j].status = Status.Locked;
                }
            }
        }
        return totalToSwap;
    }

    function _swap(Pair memory _pair, uint256 _amount, address _receiver) internal returns(uint256) {
        //require(block.timestamp >= lastSwapTime + swapInterval, "DCAUniswapV2: Not enough time has passed since the last swap");
        require(IERC20(_pair.token_from).balanceOf(address(this)) > _amount, "Insufficient balance of origin Token");
        IERC20(_pair.token_from).approve(address(uniswapRouter), _amount);

        address pair = IUniswapV2Factory(IUniswapV2Router02(uniswapRouter).factory()).getPair(address(_pair.token_from), address(_pair.token_to));
        if (pair != address(0)){

            address[] memory path = new address[](2);
            path[0] = address(_pair.token_from);
            path[1] = address(_pair.token_to);

            if (_amount != 0){
                    uint[] memory outputAmounts = uniswapRouter.swapExactTokensForTokens(_amount, 0, path, _receiver, block.timestamp + 1800);
                    return outputAmounts[1];
            }
            else{
                return 0;
            }
        }
        else{
            revert("Pair doesn't exist");
        }
    }

    function _positionExists(address _user, Position memory _position) internal view returns (bool) {
        Position[] memory positions = users[_user].positions;
        for (uint256 i = 0; i < positions.length; i++) {
            if(keccak256(abi.encodePacked(_position.name)) == keccak256(abi.encodePacked(positions[i].name)) &&
                _position.pair.token_from == positions[i].pair.token_from && _position.pair.token_to == positions[i].pair.token_to) {
                return true;
            }
        }
        return false;
    }

    function _positionExists(address _user, string memory _name, Pair memory _pair) internal view returns (bool) {
        Position[] memory positions = users[_user].positions;
        for (uint256 i = 0; i < positions.length; i++) {
            if(keccak256(abi.encodePacked(_name)) == keccak256(abi.encodePacked(positions[i].name)) &&
                _pair.token_from == positions[i].pair.token_from && _pair.token_to == positions[i].pair.token_to) {
                return true;
            }
        }
        return false;
    }

    function _getAllInputTokenAddresses() external view returns (address[] memory) {
        address[] memory tokenAddresses = new address[](pairsAvailable.length);
        uint256 distinctTokenCount = 0;
        
        for (uint256 i = 0; i < pairsAvailable.length; i++) {
            // Check if the token_from address has already been added to the list
            bool exists = false;
            for (uint256 j = 0; j < distinctTokenCount; j++) {
                if (tokenAddresses[j] == address(pairsAvailable[i].token_from)) {
                    exists = true;
                    break;
                }
            }
            // If token_from has not been added to the list yet, add it
            if (!exists) {
                tokenAddresses[distinctTokenCount] = address(pairsAvailable[i].token_from);
                distinctTokenCount++;
            }
        }
        // Resize the tokenAddresses array to remove any empty elements
        assembly {
            mstore(tokenAddresses, distinctTokenCount)
        } 
        return tokenAddresses;
    }

    function _checkValidERC20(address tokenAddress) internal view returns (bool) {
        try IERC20(tokenAddress).totalSupply() returns (uint256 _supply) {
            if (_supply > 0 ){
                return true;
            }
            return false;
        } catch (bytes memory) {
            return false;
        }
    }

    function _achivePosition(address _user, uint _positionId) internal returns (bool) {
        users[_user].closedPositions.push( users[_user].positions[_positionId]);
        users[_user].positions[_positionId] =  users[_user].positions[users[_user].positions.length - 1];
        users[_user].positions.pop();
    }


    function addPair(address _token_from, address _token_to, bool _active) external onlyOwner {
        require(_token_from != _token_to, "Input and Output tokens must be different");
        require(_checkValidERC20(_token_from), "Input Token is not available. No Supply");
        require(_checkValidERC20(_token_to), "Output Token is not available. No Supply");
        require(!_pairExists(Pair(IERC20(_token_from), IERC20(_token_to), true)), "Pair already exists");
        pairsAvailable.push(Pair(IERC20(_token_from), IERC20(_token_to), _active)); 
        emit PairAdded(_token_from, _token_to, block.timestamp);
    }

    function addInterval(uint256 _interval) external onlyOwner {
        require(!_intervalExists(_interval), "Interval already added");
        intervalsAvailable.push(_interval); 
        emit IntervalAdded(_interval, block.timestamp);
    }

    function createPosition(string calldata _name, Pair calldata _pair, uint _totalAmountToSwap, uint _interval, uint _amountPerSwap, uint _dcaIterations, bool _stacking) external {
        require(bytes(_name).length > 0, "name must be set"); 
        require(!_positionExists(msg.sender, _name, _pair), "Position is already existing");
        require(_pairExists(_pair), "pair not available");
        require(_intervalExists(_interval), "this interval is not allowed");
        require(_totalAmountToSwap > 0, "No amount set for DCA");
        require( (_amountPerSwap == 0 && _dcaIterations != 0) || (_amountPerSwap != 0 && _dcaIterations == 0), "Set only amount per swap or number of iterations" );

        uint totalToSwapAfterFees = _totalAmountToSwap - (_totalAmountToSwap * depositFee / 10000);
        uint amountPerSwap = _amountPerSwap > 0 ? _amountPerSwap : ((totalToSwapAfterFees * 10000) / _dcaIterations) / 10000;

        SafeERC20.safeTransferFrom(_pair.token_from, msg.sender, address(this), _totalAmountToSwap);   
        if (!_userExists(msg.sender)){
            userAddresses.push(msg.sender);
        }
        users[msg.sender].positions.push(Position(_name, _pair, totalToSwapAfterFees, _interval, _dcaIterations, amountPerSwap, block.timestamp, block.timestamp, 0, 0, Status.Active ,msg.sender, _stacking, _dcaIterations == 0 ? DcaMode.Unlimited : DcaMode.Limited ));
    
        emit PositionCreated (msg.sender, users[msg.sender].positions.length-1, block.timestamp);  
    }

    function setPositionStatus(uint _positionId, Status _status) external {
        require(_positionId < users[msg.sender].positions.length , "Position doesn't exist");
        users[msg.sender].positions[_positionId].status=_status;
        emit PositionStatusChanged (msg.sender, _positionId, _status, block.timestamp);  
    }

    function closePosition(uint _positionId) external {
        require(_positionId < users[msg.sender].positions.length , "Position doesn't exist");
        Position memory positionToClose = users[msg.sender].positions[_positionId];
        require(positionToClose.status != Status.Locked, "Position is Locked: non closable");

        if ( (positionToClose.totalAmountToSwap - positionToClose.SwappedFromBalance) > 0 ) {
            SafeERC20.safeTransfer(positionToClose.pair.token_from, msg.sender, positionToClose.totalAmountToSwap - positionToClose.SwappedFromBalance);
            emit TokenClaimed( address (positionToClose.pair.token_from), positionToClose.totalAmountToSwap - positionToClose.SwappedFromBalance, block.timestamp );
        }
        if ( (positionToClose.SwappedToBalance) > 0 ) {
            // swapped token could only be claimed for staking position. not stacking position swap directly to the user wallet.
            if (positionToClose.stacking == true){
                SafeERC20.safeTransfer(positionToClose.pair.token_to, msg.sender, positionToClose.SwappedToBalance);
                emit TokenClaimed( address (positionToClose.pair.token_to), positionToClose.SwappedToBalance, block.timestamp );
            }
        }
        users[msg.sender].positions[_positionId].status = Status.Closed;
        _achivePosition(msg.sender, _positionId);
        emit PositionStatusChanged (msg.sender, _positionId, Status.Closed, block.timestamp);  
    }

    function claimRewards(uint _positionId) external {
        //require(_positionId < users[msg.sender].positions.length , "Position doesn't exist");
        //users[msg.sender].positions[_positionId].status = Status.Closed;
    }

    function claimFees(uint _positionId) external {
        require(_positionId < users[msg.sender].positions.length , "Position doesn't exist");
        users[msg.sender].positions[_positionId].status = Status.Closed;
        //emit PositionStatusChanged (msg.sender, _positionId, Status.Closed);  
    }

    function getPosition(uint _positionId) external view returns (Position memory){
        return users[msg.sender].positions[_positionId];
    }

    function executeSwap() external onlyOwner{
        _executeIndividualDCA();
        _executeStakedDCA();
    }

    event PairAdded(address token_from, address token_to, uint date);
    event IntervalAdded(uint256 interval, uint date);
    event PositionCreated (address sender, uint256 id, uint date);
    event PositionStatusChanged (address sender, uint256 id, Status status, uint date);
    event DCAExecuted (address user, uint positionId, address token_from, address token_to, uint amountToSwap, uint amountSwapped, uint date);
    event TokenClaimed (address token, uint amount, uint date);

}

