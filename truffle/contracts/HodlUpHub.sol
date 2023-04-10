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

    /**
     * @dev Enum representing the available DCA modes.
     * Limited: the position has a fixed number of swaps.
     * Unlimited: the position will continue to swap indefinitely.
     */
    enum DcaMode {
        Limited,
        Unlimited
    }

    /**
     * @dev The available pairs for swapping.
     */
    Pair[] public pairsAvailable;

    /**
    * @dev The available intervals (in seconds) for swapping.
    */ 
    uint256[] public intervalsAvailable;

    /**
    * @dev The Uniswap V2 router.
    */
    IUniswapV2Router02 public uniswapRouter;

    /**
     * @dev Struct representing a user's data.
     * positions: An array of the user's open positions.
     * closedPositions: An array of the user's closed positions.
     */
    struct User {
        Position[] positions;
        Position[] closedPositions;
    }

    /**
     * @dev Struct representing a pair of tokens for swapping.
     * token_from: The token to be swapped from.
     * token_to: The token to be swapped to.
     * active: A flag indicating whether the pair is currently available for swapping.
     */
    struct Pair {
        IERC20 token_from;
        IERC20 token_to;
        bool active;
    }


    /**
     * @dev Struct representing a user's position.
     * name: The name of the position.
     * pair: The pair of tokens to be swapped.
     * totalAmountToSwap: The total amount of token_from to be swapped.
     * interval: The time interval (in seconds) between swaps.
     * dcaIterations: The number of swaps remaining for the position (in case of Limited DCA mode).
     * amountPerSwap: The amount of token_from to be swapped per interval.
     * lastPurchaseTimestamp: The timestamp of the last swap.
     * createdTimestamp: The timestamp of the position creation.
     * SwappedFromBalance: The total amount of token_from swapped so far.
     * SwappedToBalance: The total amount of token_to received so far.
     * status: The current status of the position.
     * recipient: The address to receive the swapped tokens.
     * stacking: A flag indicating whether the position is stacking.
     * mode: The DCA mode of the position.
     */
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

    /**
    * @dev Mapping that stores information about each user.
    */
    mapping(address => User) users;

    /**
    * @dev Array that stores the addresses of all registered users.
    */   
    address [] public userAddresses;

    /**
    * @dev Mapping that stores the balances of fees collected for each ERC20 token.
    */
    mapping(IERC20 => uint) feesBalances;

    /**
    * @dev Represents the fee percentage taken for deposits. 
    *      To avoid rounding errors, the percentage is multiplied by 10000. 
    *      For example, 1% is represented by 100.
    */
    uint public depositFee;

    /**
    * @dev Represents the fee percentage taken for swaps. 
    *      To avoid rounding errors, the percentage is multiplied by 10000. 
    *      For example, 1% is represented by 100.
    */ 
    uint public swapFee;

    /**
    * @dev the reward manager instance.
    */
    IHodlUpRewardsManager public rewardsManager;

    /**
    * @dev HodlUpHub constructor.
    * @param _uniswapRouter Address of the Uniswap router contract.
    * @param _rewardManager Address of the rewards manager contract.
    * @param _depositFee Deposit fee percentage charged from each deposit.
    * @param _swapFee Swap fee percentage charged from each swap.
    */
    constructor(address _uniswapRouter, address _rewardManager, uint _depositFee, uint _swapFee) {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        rewardsManager = IHodlUpRewardsManager(_rewardManager);
        depositFee = _depositFee;
        swapFee = _swapFee;
    }

    /**
    * @dev Returns a boolean indicating whether a user with the specified address exists in the `users` mapping.
    * @param _userAddress The address of the user to check.
    * @return True if the user exists, false otherwise.
    */
    function _userExists(address _userAddress) internal view returns (bool) {
        return (users[_userAddress].positions.length > 0);
    }

    /**
    @dev Executes a staked DCA for all available pairs, for all eligible positions of all users.
    The function iterates over all available pairs and for each pair, it calculates the total amount to swap
    and the swap fees. Then it swaps the tokens using the UniswapV2Router02 contract. After the swap,
    it updates the balances of the users positions and emits a DCAExecuted event.
    If the amount to swap for a position is greater than the remaining amount, the status of the position is set to "Pause".
    If the DCA mode for the position is "Limited", the remaining number of iterations is decreased by 1.
    If the amount to swap is less than the remaining amount, the position is updated with the swapped amount and the status is set to "Active" (Locked status removing).
    Finally, the function generates rewards for the user based on the swapped amount.
    */
    function _executeStakedDCA () internal {
        for (uint i = 0; i < pairsAvailable.length; i++) {
            uint totalToSwap = _getTotalToSwap(pairsAvailable[i]);
            uint swapFees = (totalToSwap * swapFee / 10000);
            uint totalToSwapAfterFees = totalToSwap - swapFees;
            uint totalSwapped = _swap(pairsAvailable[i], totalToSwapAfterFees, address(this)) ;
            feesBalances[pairsAvailable[i].token_from]+=swapFees;
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
                            _generateRewards(userAddresses[j], ERC20(address(positions[k].pair.token_to)), amountSwapped);
                        }
                     }
                }
            }
        }
    }

    /**
    * @dev Executes the DCA strategy for all active positions of all users.
    * Checks if the current time is greater than the last purchase timestamp
    * plus the interval of the position. If so, executes a swap of the amountPerSwap
    * for the token_from in the position's pair to the token_to in the pair,
    * subtracts the swap fee from the amount and adds it to the feesBalances,
    * and updates the balances and status of the position.
    * If the amountPerSwap is greater than the remaining amount to swap,
    * pauses the position and emits a PositionStatusChanged event.
    * Emits a DCAExecuted event on successful execution of the swap.
    */
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
                        uint swapFees = (positions[j].amountPerSwap * swapFee / 10000);
                        uint amoutPerSwapAfterFees =  positions[j].amountPerSwap - (swapFees);
                        uint resultSwap = _swap( positions[j].pair, amoutPerSwapAfterFees, positions[j].recipient) ;
                        feesBalances[positions[j].pair.token_from]+=swapFees;
                        if (positions[j].mode == DcaMode.Limited){
                            users[userAddresses[i]].positions[j].dcaIterations -= 1 ;
                        }
                        users[userAddresses[i]].positions[j].SwappedToBalance += resultSwap;
                        users[userAddresses[i]].positions[j].SwappedFromBalance += positions[j].amountPerSwap;
                        users[userAddresses[i]].positions[j].status = Status.Active;
                        users[userAddresses[i]].positions[j].lastPurchaseTimestamp = block.timestamp;
                        emit DCAExecuted (userAddresses[i], j, address(positions[j].pair.token_from), address(positions[j].pair.token_to), positions[j].amountPerSwap, resultSwap, block.timestamp);
                    }
                }
            }
        }
    }

    /**
    * @dev Checks if a given pair already exists in the pairsAvailable array.
    * @param _pair The pair to check.
    * @return A boolean indicating whether the given pair exists.
    */
    function _pairExists(Pair memory _pair) internal view returns (bool) {
        for (uint i = 0; i < pairsAvailable.length; i++) {
            if (pairsAvailable[i].token_from == _pair.token_from && pairsAvailable[i].token_to == _pair.token_to) {
                return true;
            }
        }
        return false;
    }

    /**
    * @dev Checks if a given interval already exists in the intervalsAvailable array.
    * @param interval The interval to check.
    * @return A boolean indicating whether the given interval exists.
    */
    function _intervalExists(uint256 interval) internal view returns (bool) {
        for (uint i = 0; i < intervalsAvailable.length; i++) {
            if (intervalsAvailable[i]==interval) {
                return true;
            }
        }
        return false;
    }

    /**
    * @dev Calculates the total amount of tokens to swap for a given token pair.
    * @param _pair The token pair to swap.
    * @return The total amount of tokens to swap.
    */
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

    /**
    * @dev Internal function to check if a position already exists for a given user and Pair.
    * @param _user The user address.
    * @param _name The name of the position.
    * @param _pair The Pair struct.
    * @return bool Returns true if the position exists, false otherwise.
    */
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

    /**
    * @dev Internal function to get all input tokens from available pairs.
    * @return IERC20[] Returns an array of IERC20 tokens.
    */
    function _getAllInputToken() internal view returns (IERC20[] memory) {
        IERC20[] memory tokenAddresses = new IERC20[](pairsAvailable.length);
        uint256 distinctTokenCount = 0;
        
        for (uint256 i = 0; i < pairsAvailable.length; i++) {
            // Check if the token_from address has already been added to the list
            bool exists = false;
            for (uint256 j = 0; j < distinctTokenCount; j++) {
                if (tokenAddresses[j] == pairsAvailable[i].token_from) {
                    exists = true;
                    break;
                }
            }
            // If token_from has not been added to the list yet, add it
            if (!exists) {
                tokenAddresses[distinctTokenCount] = pairsAvailable[i].token_from;
                distinctTokenCount++;
            }
        }
        // Resize the tokenAddresses array to remove any empty elements
        assembly {
            mstore(tokenAddresses, distinctTokenCount)
        } 
        return tokenAddresses;
    }

    /**
    * @dev Internal function to check if a token at a given address is a valid ERC20 token.
    * @param tokenAddress The token address.
    * @return bool Returns true if the token is a valid ERC20 token, false otherwise.
    */
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

    /**
    * @dev Internal function to archive the user's position by moving it to the closedPositions array and removing it from positions array.
    * @param _user The user's address.
    * @param _positionId The position ID to archive.
    */
    function _achivePosition(address _user, uint _positionId) internal {
        users[_user].closedPositions.push( users[_user].positions[_positionId]);
        users[_user].positions[_positionId] =  users[_user].positions[users[_user].positions.length - 1];
        users[_user].positions.pop();
    }

    /**
    * @dev Add a new token pair to the pairsAvailable array.
    * @param _token_from The address of the input token.
    * @param _token_to The address of the output token.
    * @param _active Whether the pair is active or not.
    * Requirements:
    * - The input and output tokens must be different.
    * - The input token must be a valid ERC20 token with a total supply greater than 0.
    * - The output token must be a valid ERC20 token with a total supply greater than 0.
    * - The pair does not already exist in pairsAvailable.
    */
    function addPair(address _token_from, address _token_to, bool _active) external onlyOwner {
        require(_token_from != _token_to, "Input and Output tokens must be different");
        require(_checkValidERC20(_token_from), "Input Token is not available. No Supply");
        require(_checkValidERC20(_token_to), "Output Token is not available. No Supply");
        require(!_pairExists(Pair(IERC20(_token_from), IERC20(_token_to), true)), "Pair already exists");
        pairsAvailable.push(Pair(IERC20(_token_from), IERC20(_token_to), _active)); 
        emit PairAdded(_token_from, _token_to, block.timestamp);
    }

    /**
    * @dev Add a new interval to the intervalsAvailable array.
    * @param _interval The interval value to add.
    * Requirements:
    * - The interval value has not been added previously.
    */
    function addInterval(uint256 _interval) external onlyOwner {
        require(!_intervalExists(_interval), "Interval already added");
        intervalsAvailable.push(_interval); 
        emit IntervalAdded(_interval, block.timestamp);
    }

    /**
    * @dev Create a new position for the user.
    * @param _name The name of the position.
    * @param _pair The pair to swap for the position.
    * @param _totalAmountToSwap The total amount to swap for the position.
    * @param _interval The interval for DCA swaps.
    * @param _amountPerSwap The amount to swap per DCA iteration.
    * @param _dcaIterations The number of DCA iterations.
    * @param _stacking Whether the user wants to stack rewards.
    * Requirements:
    * - The name must be set.
    * - The position does not already exist for the user.
    * - The pair exists in pairsAvailable.
    * - The interval exists in intervalsAvailable.
    * - The total amount to swap is greater than 0.
    * - Either the amount per swap or the number of DCA iterations is set, but not both.
    */
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

    /**
    * @dev Set the status of a user's position.
    * @param _positionId The ID of the position to update.
    * @param _status The new status of the position.
    * Emits a {PositionStatusChanged} event.
    * Requirements:
    * - The position must exist.
    */
    function setPositionStatus(uint _positionId, Status _status) external {
        require(_positionId < users[msg.sender].positions.length , "Position doesn't exist");
        users[msg.sender].positions[_positionId].status=_status;
        emit PositionStatusChanged (msg.sender, _positionId, _status, block.timestamp);  
    }

    /**
    * @dev Close a position and transfer any remaining tokens back to the user's wallet.
    * @param _positionId The ID of the position to close.
    * Requirements:
    * - The position must exist.
    * - The position must not be locked.
    */
    function closePosition(uint _positionId) external {
        require(_positionId < users[msg.sender].positions.length , "Position doesn't exist");
        Position memory positionToClose = users[msg.sender].positions[_positionId];
        require(positionToClose.status != Status.Locked, "Position is Locked: non closable");

        if ( (positionToClose.totalAmountToSwap - positionToClose.SwappedFromBalance) > 0 ) {
            SafeERC20.safeTransfer(positionToClose.pair.token_from, msg.sender, positionToClose.totalAmountToSwap - positionToClose.SwappedFromBalance);
            emit TokenClaimed( address (positionToClose.pair.token_from), positionToClose.totalAmountToSwap - positionToClose.SwappedFromBalance, block.timestamp );
        }
        if ( (positionToClose.SwappedToBalance) > 0 ) {
            if (positionToClose.stacking == true){
                SafeERC20.safeTransfer(positionToClose.pair.token_to, msg.sender, positionToClose.SwappedToBalance);
                emit TokenClaimed( address (positionToClose.pair.token_to), positionToClose.SwappedToBalance, block.timestamp );
            }
        }
        users[msg.sender].positions[_positionId].status = Status.Closed;
        _achivePosition(msg.sender, _positionId);
        emit PositionStatusChanged (msg.sender, _positionId, Status.Closed, block.timestamp);  
    }

    /**
    * @dev Claim rewards for a closed position.
    * @param _positionId The ID of the closed position to claim rewards for.
    * Requirements:
    * - The position must exist.
    * - The position must be closed.
    */
    function claimRewards(uint _positionId) external {
    }

    /**
    * @dev Claim all fees collected by the contract.
    * Requirements:
    * - The caller must be the contract owner.
    */
    function claimFees() external onlyOwner{
        IERC20[] memory tokens = _getAllInputToken();
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 balance = tokens[i].balanceOf(address(this));
            if (balance > 0) {
                SafeERC20.safeTransfer(tokens[i], msg.sender, feesBalances[tokens[i]]);
            }
        }
    }

    /**
    * @dev Get a position by ID.
    * @param _positionId The ID of the position to get.
    * @return The position object.
    */
    function getPosition(uint _positionId) external view returns (Position memory){
        return users[msg.sender].positions[_positionId];
    }

    /**
    * @dev Execute swaps for all individual and staked DCA positions.
    * Requirements:
    * - The caller must be the contract owner.
    */
    function executeSwap() external onlyOwner{
        _executeIndividualDCA();
        _executeStakedDCA();
    }

    /**
    * @dev Generate rewards for a user.
    * @param _user The address of the user to generate rewards for.
    * @param _token The token to generate rewards for.
    * @param _amount The amount of rewards to generate.
    * Requirements:
    * - The caller must be an authorized rewards manager.
    */
    function _generateRewards(address _user, ERC20 _token, uint _amount) internal {
       //rewardsManager.generateRewards(_user, _token, _amount);
    }

    /**
    * @dev Emitted when a new pair is added to the contract.
    * @param token_from The address of the ERC20 token being swapped from.
    * @param token_to The address of the ERC20 token being swapped to.
    * @param date The timestamp of when the event was emitted.
    */
    event PairAdded(address token_from, address token_to, uint date);

    /**
    * @dev Emitted when a new DCA interval is added to the contract.
    * @param interval The DCA interval in seconds.
    * @param date The timestamp of when the event was emitted.
    */
    event IntervalAdded(uint256 interval, uint date);

    /**
    * @dev Emitted when a new position is created.
    * @param sender The address of the user who created the position.
    * @param id The ID of the position created.
    * @param date The timestamp of when the event was emitted.
    */
    event PositionCreated (address indexed sender, uint256 id, uint date);

    /**
    * @dev Emitted when the status of a position is changed.
    * @param sender The address of the user who changed the position status.
    * @param id The ID of the position whose status was changed.
    * @param status The new status of the position.
    * @param date The timestamp of when the event was emitted.
    */
    event PositionStatusChanged (address indexed sender, uint256 id, Status status, uint date);

    /**
    * @dev Emitted when a DCA is executed.
    * @param user The address of the user who executed the DCA.
    * @param positionId The ID of the position associated with the DCA.
    * @param token_from The address of the ERC20 token being swapped from.
    * @param token_to The address of the ERC20 token being swapped to.
    * @param amountToSwap The amount of token_from being swapped.
    * @param amountSwapped The amount of token_to received in the swap.
    * @param date The timestamp of when the event was emitted.
    */   
    event DCAExecuted (address user, uint positionId, address token_from, address token_to, uint amountToSwap, uint amountSwapped, uint date);
    
    /**
    * @dev Emitted when a token is claimed from a position.
    * @param token The address of the ERC20 token being claimed.
    * @param amount The amount of the token being claimed.
    * @param date The timestamp of when the event was emitted.
    */
    event TokenClaimed(address token, uint amount, uint date);

}

