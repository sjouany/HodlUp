// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "../node_modules/@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

using SafeERC20 for IERC20;

/**
 * @title HodlUpHub contract
 * @dev This contract is used for hodling tokens and executing automated periodic swaps.
 */
contract DcaHodlup is Ownable {
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
    IERC20 inputToken;
    IERC20 outputToken;

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
        mapping(string => Position) positions;
        string[] positionsKeys;
        mapping(string => Position) closedPositions;
        string[] closedPositionsKeys;
    }

    /**
     * @dev Struct representing a user's position.
     * name: The name of the position.
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
     * mode: The DCA mode of the position.
     */
    struct Position {
        string name;
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
     * @param _swapFee Swap fee percentage charged from each swap.
     */
    constructor(address _inputToken, address _outputToken, address _uniswapRouter, uint256 _swapFee) {
        inputToken = IERC20(_inputToken);
        outputToken = IERC20(_outputToken);
        swapRouter = ISwapRouter(_uniswapRouter);
        swapFee = _swapFee;
    }

    /**
     * @dev Emitted when a new position is created.
     * @param sender The address of the user who created the position.
     * @param name The name of the position created.
     * @param date The timestamp of when the event was emitted.
     */
    event PositionCreated(address indexed sender, address token_from, address token_to, string name, uint256 date);

    /**
     * @dev Emitted when the status of a position is changed.
     * @param sender The address of the user who changed the position status.
     * @param name The name of the position whose status was changed.
     * @param status The new status of the position.
     * @param date The timestamp of when the event was emitted.
     */
    event PositionStatusChanged(
        address indexed sender, address token_from, address token_to, string name, Status status, uint256 date
    );

    /**
     * @dev Emitted when a DCA is executed.
     * @param user The address of the user who executed the DCA.
     * @param name The name of the position associated with the DCA.
     * @param token_from The address of the ERC20 token being swapped from.
     * @param token_to The address of the ERC20 token being swapped to.
     * @param amountToSwap The amount of token_from being swapped.
     * @param amountSwapped The amount of token_to received in the swap.
     * @param date The timestamp of when the event was emitted.
     */
    event DCAExecuted(
        address user,
        string name,
        address token_from,
        address token_to,
        uint256 amountToSwap,
        uint256 amountSwapped,
        uint256 date
    );

    modifier positionExists(string memory _positionName) {
        _positionExists(_positionName);
        _;
    }

    function _positionExists(string memory _positionName) internal view {
        require(accounts[msg.sender].positions[_positionName].createdTimestamp > 0, "Position doesn't exist");
    }

    /**
     * @dev Returns a boolean indicating whether a user with the specified address exists in the `accounts` mapping.
     * @param _userAddress The address of the user to check.
     * @return True if the user exists, false otherwise.
     */
    function _userExists(address _userAddress) internal view returns (bool) {
        return (accounts[_userAddress].positionsKeys.length > 0 || accounts[_userAddress].closedPositionsKey.length > 0);
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
            Position[] memory positionsKeys = accounts[userAddresses[i]].positionsKeys;
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
     * @dev Calculates the total amount of tokens to swap for a given token pair.
     * @param _pair The token pair to swap.
     * @return The total amount of tokens to swap.
     */
    function _getTotalToSwap() internal returns (uint256) {
        uint256 totalToSwap;
        for (uint256 i = 0; i < userAddresses.length; i++) {
            Position[] memory positions = accounts[userAddresses[i]].positions;
            for (uint256 j = 0; j < positions.length; j++) {
                if (
                    positions[j].status == Status.Active 
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

    function _closePosition(address _user, string _name) internal {
        accounts[_user].positions[_name].status = Status.Closed;
        _achivePosition(_user, _name);
        closedPositionsKeys.push(_name);
        accounts[_user].closedPositions[_name] = accounts[_user].positions[_name];
        delete(accounts[_user].positions[_name]);
        for (uint256 i = 0; i < positionsKeys.length; i++) {
            string memory _key = positionsKeys[i];
            if (keccak256(abi.encodePacked(_name)) == keccak256(abi.encodePacked(_key))) {
                positionsKeys[i] = positionsKeys[positionsKeys.length - 1];
                positionsKeys.pop();
                break;
            }
        }
        emit PositionStatusChanged(_user, inputToken, outputToken, _name, Status.Closed, block.timestamp);
    }

    /**
     * @dev Create a new position for the user.
     * @param _name The name of the position.
     * @param _totalAmountToSwap The total amount to swap for the position.
     * @param _interval The interval for DCA swaps.
     * @param _amountPerSwap The amount to swap per DCA iteration.
     * @param _dcaIterations The number of DCA iterations.
     * Requirements:
     * - The name must be set.
     * - The position does not already exist for the user.
     * - The interval exists in intervalsAvailable.
     * - The total amount to swap is greater than 0.
     * - Either the amount per swap or the number of DCA iterations is set, but not both.
     */
    function createPosition(
        string calldata _name,
        uint256 _totalAmountToSwap,
        uint256 _interval,
        uint256 _amountPerSwap,
        uint256 _dcaIterations
    ) external {
        require(bytes(_name).length > 0, "name must be set");
        require(accounts[msg.sender].positions[_positionName].createdTimestamp == 0, "Position is already existing");
        require(_interval >= 86400, "this interval is not allowed");
        require(_totalAmountToSwap > 0, "No amount set for DCA");
        require(
            (_amountPerSwap == 0 && _dcaIterations != 0) || (_amountPerSwap != 0 && _dcaIterations == 0),
            "Set only amount per swap or number of iterations"
        );

        // uint256 totalToSwapAfterFees = _totalAmountToSwap - (_totalAmountToSwap * depositFee / 10000);
        uint256 amountPerSwap =
            _amountPerSwap > 0 ? _amountPerSwap : ((_totalAmountToSwap * 10000) / _dcaIterations) / 10000;

        SafeERC20.safeTransferFrom(inputToken, msg.sender, address(this), _totalAmountToSwap);
        // uint256 allowanceAmount = _pair.token_from.allowance(address(_pair.token_from), msg.sender);
        // if ( allowanceAmount == 0) {
        //     SafeERC20.safeApprove(_pair.token_from, msg.sender, _totalAmountToSwap);
        // } else {
        //     SafeERC20.safeIncreaseAllowance(_pair.token_from, msg.sender, _totalAmountToSwap);
        // }

        if (!_userExists(msg.sender)) {
            userAddresses.push(msg.sender);
        }
        accounts[msg.sender].positions[_name] = Position(
            _name,
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
            _dcaIterations == 0 ? DcaMode.Unlimited : DcaMode.Limited
        );

        positionsKeys.push(_name);

        emit PositionCreated(msg.sender, inputToken, outputToken, _name, block.timestamp);
    }

    /**
     * @dev Set the status of a user's position.
     * @param _name The name of the position to update.
     * @param _status The new status of the position.
     * Emits a {PositionStatusChanged} event.
     * Requirements:
     * - The position must exist.
     */
    function setPositionStatus(string _name, Status _status) external positionExists(_name) {
        accounts[msg.sender].positions[_name].status = _status;
        emit PositionStatusChanged(msg.sender, inputToken, outputToken, _name, _status, block.timestamp);
    }

    /**
     * @dev Close a position and transfer any remaining tokens back to the user's wallet.
     * @param _name The ID of the position to close.
     * Requirements:
     * - The position must exist.
     * - The position must not be locked.
     */
    function closePosition(string _name) external positionExists(_name) {
        _closePosition(msg.sender, _name);
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
     * @dev Get a position by name.
     * @param _name The name of the position to get.
     * @return The position object.
     */
    function getPosition(string calldata _name) external view returns (Position calldata) {
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
}
