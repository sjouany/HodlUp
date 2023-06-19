// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "../node_modules/@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

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
     * @dev The Uniswap V3 router.
     */
    ISwapRouter swapRouter;

    /**
     * @dev Struct representing a user's data.
     * positions: An array of the user's open positions.
     * closedPositions: An array of the user's closed positions.
     */
    struct Account {
        Position[] positions;
        Position[] positionsToExecute;
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
        uint256 totalAmountToSwap;
        uint256 interval;
        uint256 dcaIterations;
        uint256 amountPerSwap;
        uint256 lastPurchaseTimestamp;
        uint256 createdTimestamp;
        uint256 SwappedFromBalance;
        uint256 SwappedToBalance;
        Status status;
        address recipient;
        bool stacking;
        DcaMode mode;
    }

    /**
     * @dev Mapping that stores information about each user.
     */
    mapping(address => Account) accounts;

    /**
     * @dev Array that stores the addresses of all registered accounts.
     */
    address[] public userAddresses;

    /**
     * @dev Mapping that stores the balances of fees collected for each ERC20 token.
     */
    mapping(IERC20 => uint256) feesBalances;

    /**
     * @dev Represents the fee percentage taken for deposits.
     *      To avoid rounding errors, the percentage is multiplied by 10000.
     *      For example, 1% is represented by 100.
     */
    uint256 public depositFee;

    /**
     * @dev Represents the fee percentage taken for swaps.
     *      To avoid rounding errors, the percentage is multiplied by 10000.
     *      For example, 1% is represented by 100.
     */
    uint256 public swapFee;

    uint256 private currentUserindex;
    uint256 private operationsLimit;

    /**
     * @dev HodlUpHub constructor.
     * @param _uniswapRouter Address of the Uniswap router contract.
     * @param _depositFee Deposit fee percentage charged from each deposit.
     * @param _swapFee Swap fee percentage charged from each swap.
     */
    constructor(address _uniswapRouter, uint256 _depositFee, uint256 _swapFee) {
        swapRouter = ISwapRouter(_uniswapRouter);
        depositFee = _depositFee;
        swapFee = _swapFee;
    }

    /**
     * @dev Returns a boolean indicating whether a user with the specified address exists in the `accounts` mapping.
     * @param _userAddress The address of the user to check.
     * @return True if the user exists, false otherwise.
     */
    function _userExists(address _userAddress) internal view returns (bool) {
        return (accounts[_userAddress].positions.length > 0);
    }

    /**
     * @dev Executes the DCA strategy for all active positions of all accounts.
     * Checks if the current time is greater than the last purchase timestamp
     * plus the interval of the position. If so, executes a swap of the amountPerSwap
     * for the token_from in the position's pair to the token_to in the pair,
     * subtracts the swap fee from the amount and adds it to the feesBalances,
     * and updates the balances and status of the position.
     * If the amountPerSwap is greater than the remaining amount to swap,
     * pauses the position and emits a PositionStatusChanged event.
     * Emits a DCAExecuted event on successful execution of the swap.
     */
    function _executeIndividualDCA() internal {
        for (uint256 i = 0; i < userAddresses.length; i++) {
            Position[] memory positions = accounts[userAddresses[i]].positions;
            for (uint256 j = 0; j < positions.length; j++) {
                if (
                    positions[j].status == Status.Active && positions[j].stacking == false
                        && block.timestamp > (positions[j].lastPurchaseTimestamp + positions[j].interval)
                ) {
                    if (positions[j].amountPerSwap > (positions[j].totalAmountToSwap - positions[j].SwappedFromBalance))
                    {
                        accounts[userAddresses[i]].positions[j].status = Status.Pause;
                        emit PositionStatusChanged(userAddresses[i], j, Status.Pause, block.timestamp);
                    } else {
                        accounts[userAddresses[i]].positions[j].status = Status.Locked;
                        SafeERC20.safeTransferFrom(
                            positions[j].pair.token_from, userAddresses[i], address(this), positions[j].amountPerSwap
                        );
                        uint256 swapFees = (positions[j].amountPerSwap * swapFee / 10000);
                        uint256 amoutPerSwapAfterFees = positions[j].amountPerSwap - (swapFees);
                        uint256 resultSwap = _swap(positions[j].pair, amoutPerSwapAfterFees, positions[j].recipient);
                        feesBalances[positions[j].pair.token_from] += swapFees;
                        if (positions[j].mode == DcaMode.Limited) {
                            accounts[userAddresses[i]].positions[j].dcaIterations -= 1;
                        }
                        accounts[userAddresses[i]].positions[j].SwappedToBalance += resultSwap;
                        accounts[userAddresses[i]].positions[j].SwappedFromBalance += positions[j].amountPerSwap;
                        accounts[userAddresses[i]].positions[j].status = Status.Active;
                        accounts[userAddresses[i]].positions[j].lastPurchaseTimestamp = block.timestamp;
                        emit DCAExecuted(
                            userAddresses[i],
                            j,
                            address(positions[j].pair.token_from),
                            address(positions[j].pair.token_to),
                            positions[j].amountPerSwap,
                            resultSwap,
                            block.timestamp
                        );
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
        for (uint256 i = 0; i < pairsAvailable.length; i++) {
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
        for (uint256 i = 0; i < intervalsAvailable.length; i++) {
            if (intervalsAvailable[i] == interval) {
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
    function _getTotalToSwap(Pair memory _pair) internal returns (uint256) {
        uint256 totalToSwap;
        for (uint256 i = 0; i < userAddresses.length; i++) {
            Position[] memory positions = accounts[userAddresses[i]].positions;
            for (uint256 j = 0; j < positions.length; j++) {
                if (
                    positions[j].pair.token_from == _pair.token_from && positions[j].pair.token_to == _pair.token_to
                        && positions[j].status == Status.Active && positions[j].stacking == true
                        && block.timestamp > positions[j].lastPurchaseTimestamp + positions[j].interval
                ) {
                    totalToSwap += positions[j].amountPerSwap;
                    accounts[userAddresses[i]].positions[j].status = Status.Locked;
                }
            }
        }
        return totalToSwap;
    }

    function _swap(Pair memory _pair, uint256 _amount, address _receiver) internal returns (uint256) {
        require(_pair.token_from.balanceOf(address(this)) > _amount, "Insufficient balance of origin Token");

        _pair.token_from.approve(address(swapRouter), _amount);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: address(_pair.token_from),
            tokenOut: address(_pair.token_to),
            fee: 3000,
            recipient: _receiver,
            deadline: block.timestamp + 1800,
            amountIn: _amount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        if (_amount != 0) {
            uint256 amountOut = swapRouter.exactInputSingle(params);
        } else {
            return 0;
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
        Position[] memory positions = accounts[_user].positions;
        for (uint256 i = 0; i < positions.length; i++) {
            if (
                keccak256(abi.encodePacked(_name)) == keccak256(abi.encodePacked(positions[i].name))
                    && _pair.token_from == positions[i].pair.token_from && _pair.token_to == positions[i].pair.token_to
            ) {
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
            if (_supply > 0) {
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
    function _achivePosition(address _user, uint256 _positionId) internal {
        accounts[_user].closedPositions.push(accounts[_user].positions[_positionId]);
        accounts[_user].positions[_positionId] = accounts[_user].positions[accounts[_user].positions.length - 1];
        accounts[_user].positions.pop();
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
    function createPosition(
        string calldata _name,
        Pair calldata _pair,
        uint256 _totalAmountToSwap,
        uint256 _interval,
        uint256 _amountPerSwap,
        uint256 _dcaIterations,
        bool _stacking
    ) external {
        require(bytes(_name).length > 0, "name must be set");
        require(!_positionExists(msg.sender, _name, _pair), "Position is already existing");
        require(_pairExists(_pair), "pair not available");
        require(_intervalExists(_interval), "this interval is not allowed");
        require(_totalAmountToSwap > 0, "No amount set for DCA");
        require(
            (_amountPerSwap == 0 && _dcaIterations != 0) || (_amountPerSwap != 0 && _dcaIterations == 0),
            "Set only amount per swap or number of iterations"
        );

        // uint256 totalToSwapAfterFees = _totalAmountToSwap - (_totalAmountToSwap * depositFee / 10000);
        uint256 amountPerSwap =
            _amountPerSwap > 0 ? _amountPerSwap : ((_totalAmountToSwap * 10000) / _dcaIterations) / 10000;

        //SafeERC20.safeTransferFrom(_pair.token_from, msg.sender, address(this), _totalAmountToSwap);
        // uint256 allowanceAmount = _pair.token_from.allowance(address(_pair.token_from), msg.sender);
        // if ( allowanceAmount == 0) {
        //     SafeERC20.safeApprove(_pair.token_from, msg.sender, _totalAmountToSwap);
        // } else {
        //     SafeERC20.safeIncreaseAllowance(_pair.token_from, msg.sender, _totalAmountToSwap);
        // }

        if (!_userExists(msg.sender)) {
            userAddresses.push(msg.sender);
        }
        accounts[msg.sender].positions.push(
            Position(
                _name,
                _pair,
                _totalAmountToSwap,
                _interval,
                _dcaIterations,
                amountPerSwap,
                block.timestamp,
                block.timestamp,
                0,
                0,
                Status.Active,
                msg.sender,
                _stacking,
                _dcaIterations == 0 ? DcaMode.Unlimited : DcaMode.Limited
            )
        );

        emit PositionCreated(msg.sender, accounts[msg.sender].positions.length - 1, block.timestamp);
    }

    // function createPosition(
    //     string calldata _name,
    //     Pair calldata _pair,
    //     uint256 _totalAmountToSwap,
    //     uint256 _interval,
    //     uint256 _amountPerSwap,
    //     uint256 _dcaIterations,
    //     bool _stacking
    // ) external {
    //     require(bytes(_name).length > 0, "name must be set");
    //     require(!_positionExists(msg.sender, _name, _pair), "Position is already existing");
    //     require(_pairExists(_pair), "pair not available");
    //     require(_intervalExists(_interval), "this interval is not allowed");
    //     require(_totalAmountToSwap > 0, "No amount set for DCA");
    //     require(
    //         (_amountPerSwap == 0 && _dcaIterations != 0) || (_amountPerSwap != 0 && _dcaIterations == 0),
    //         "Set only amount per swap or number of iterations"
    //     );

    //     uint256 totalToSwapAfterFees = _totalAmountToSwap - (_totalAmountToSwap * depositFee / 10000);
    //     uint256 amountPerSwap =
    //         _amountPerSwap > 0 ? _amountPerSwap : ((totalToSwapAfterFees * 10000) / _dcaIterations) / 10000;

    //     SafeERC20.safeTransferFrom(_pair.token_from, msg.sender, address(this), _totalAmountToSwap);
    //     if (!_userExists(msg.sender)) {
    //         userAddresses.push(msg.sender);
    //     }
    //     accounts[msg.sender].positions.push(
    //         Position(
    //             _name,
    //             _pair,
    //             totalToSwapAfterFees,
    //             _interval,
    //             _dcaIterations,
    //             amountPerSwap,
    //             block.timestamp,
    //             block.timestamp,
    //             0,
    //             0,
    //             Status.Active,
    //             msg.sender,
    //             _stacking,
    //             _dcaIterations == 0 ? DcaMode.Unlimited : DcaMode.Limited
    //         )
    //     );

    //     emit PositionCreated(msg.sender, accounts[msg.sender].positions.length - 1, block.timestamp);
    // }

    /**
     * @dev Set the status of a user's position.
     * @param _positionId The ID of the position to update.
     * @param _status The new status of the position.
     * Emits a {PositionStatusChanged} event.
     * Requirements:
     * - The position must exist.
     */
    function setPositionStatus(uint256 _positionId, Status _status) external {
        require(_positionId < accounts[msg.sender].positions.length, "Position doesn't exist");
        accounts[msg.sender].positions[_positionId].status = _status;
        emit PositionStatusChanged(msg.sender, _positionId, _status, block.timestamp);
    }

    /**
     * @dev Close a position and transfer any remaining tokens back to the user's wallet.
     * @param _positionId The ID of the position to close.
     * Requirements:
     * - The position must exist.
     * - The position must not be locked.
     */
    function closePosition(uint256 _positionId) external {
        require(_positionId < accounts[msg.sender].positions.length, "Position doesn't exist");
        Position memory positionToClose = accounts[msg.sender].positions[_positionId];
        require(positionToClose.status != Status.Locked, "Position is Locked: non closable");

        if ((positionToClose.totalAmountToSwap - positionToClose.SwappedFromBalance) > 0) {
            SafeERC20.safeTransfer(
                positionToClose.pair.token_from,
                msg.sender,
                positionToClose.totalAmountToSwap - positionToClose.SwappedFromBalance
            );
            emit TokenClaimed(
                address(positionToClose.pair.token_from),
                positionToClose.totalAmountToSwap - positionToClose.SwappedFromBalance,
                block.timestamp
            );
        }
        if ((positionToClose.SwappedToBalance) > 0) {
            if (positionToClose.stacking == true) {
                SafeERC20.safeTransfer(positionToClose.pair.token_to, msg.sender, positionToClose.SwappedToBalance);
                emit TokenClaimed(
                    address(positionToClose.pair.token_to), positionToClose.SwappedToBalance, block.timestamp
                );
            }
        }
        accounts[msg.sender].positions[_positionId].status = Status.Closed;
        _achivePosition(msg.sender, _positionId);
        emit PositionStatusChanged(msg.sender, _positionId, Status.Closed, block.timestamp);
    }

    /**
     * @dev Claim all fees collected by the contract.
     * Requirements:
     * - The caller must be the contract owner.
     */
    function claimFees() external onlyOwner {
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
    function getPosition(uint256 _positionId) external view returns (Position memory) {
        return accounts[msg.sender].positions[_positionId];
    }

    /**
     * @dev Execute swaps for all individual and staked DCA positions.
     * Requirements:
     * - The caller must be the contract owner.
     */
    function executeSwap() external onlyOwner {
        _executeIndividualDCA();
    }

    /**
     * @dev Emitted when a new pair is added to the contract.
     * @param token_from The address of the ERC20 token being swapped from.
     * @param token_to The address of the ERC20 token being swapped to.
     * @param date The timestamp of when the event was emitted.
     */
    event PairAdded(address token_from, address token_to, uint256 date);

    /**
     * @dev Emitted when a new DCA interval is added to the contract.
     * @param interval The DCA interval in seconds.
     * @param date The timestamp of when the event was emitted.
     */
    event IntervalAdded(uint256 interval, uint256 date);

    /**
     * @dev Emitted when a new position is created.
     * @param sender The address of the user who created the position.
     * @param id The ID of the position created.
     * @param date The timestamp of when the event was emitted.
     */
    event PositionCreated(address indexed sender, uint256 id, uint256 date);

    /**
     * @dev Emitted when the status of a position is changed.
     * @param sender The address of the user who changed the position status.
     * @param id The ID of the position whose status was changed.
     * @param status The new status of the position.
     * @param date The timestamp of when the event was emitted.
     */
    event PositionStatusChanged(address indexed sender, uint256 id, Status status, uint256 date);

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
    event DCAExecuted(
        address user,
        uint256 positionId,
        address token_from,
        address token_to,
        uint256 amountToSwap,
        uint256 amountSwapped,
        uint256 date
    );

    /**
     * @dev Emitted when a token is claimed from a position.
     * @param token The address of the ERC20 token being claimed.
     * @param amount The amount of the token being claimed.
     * @param date The timestamp of when the event was emitted.
     */
    event TokenClaimed(address token, uint256 amount, uint256 date);
}
