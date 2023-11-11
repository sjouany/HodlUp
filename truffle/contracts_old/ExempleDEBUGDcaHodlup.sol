// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "../node_modules/@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../node_modules/@ganache/console.log/console.sol";

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
    function initialize(address _inputToken, address _outputToken, address _uniswapRouter, uint256 _swapFee) public {
        require(address(inputToken) == address(0), "Contract has already been initialized");
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
        return
            (accounts[_userAddress].positionsKeys.length > 0 || accounts[_userAddress].closedPositionsKeys.length > 0);
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
            uint256 posKeysLength = accounts[userAddresses[i]].positionsKeys.length;
            console.log("boucle1!!!!!!!!!");
            for (uint256 j = 0; j < posKeysLength; j++) {
                string memory positionName = accounts[userAddresses[i]].positionsKeys[j];
                Position memory position = accounts[userAddresses[i]].positions[positionName];
                console.log("boucle2!!!!!!!!!");
                if (
                    position.status == Status.Active
                        && block.timestamp > (position.lastPurchaseTimestamp + position.interval)
                ) {
                    console.log("if1!!!!!!!!!");

                    if (position.amountPerSwap > (position.totalAmountToSwap - position.SwappedFromBalance)) {
                        accounts[userAddresses[i]].positions[positionName].status = Status.Pause;
                        console.log("if2!!!!!!!!!");

                        emit PositionStatusChanged(
                            userAddresses[i],
                            address(inputToken),
                            address(outputToken),
                            positionName,
                            Status.Pause,
                            block.timestamp
                        );
                        console.log("if2.1!!!!!!!!!");
                    } else {
                        console.log("else1!!!!!!!!!");

                        console.log("!!!!!!!!!inputtoken %s",
                            address(inputToken)
                        );
                        console.log("!!!!!!!!!userAddresses %s",
                            userAddresses[i]
                        );
                        console.log("!!!!!!!!!address(this) %s",
                           address(this)
                        );
                        console.log("!!!!!!!!!amountPerSwap %d",
                           position.amountPerSwap
                        );
                        
                        accounts[userAddresses[i]].positions[positionName].status = Status.Locked;
                        SafeERC20.safeTransferFrom(inputToken, userAddresses[i], address(this), position.amountPerSwap);
                        console.log("safe!!!!!!!!!");
                        uint256 swapFees = (position.amountPerSwap * swapFee / 10000);
                        uint256 amoutPerSwapAfterFees = position.amountPerSwap - (swapFees);
                        console.log("avantSwap!!!!!!!!!");
                        uint256 resultSwap = _swap(amoutPerSwapAfterFees, position.recipient);
                        console.log("apresSwap!!!!!!!!!");
                        feesBalances[inputToken] += swapFees;
                        if (position.mode == DcaMode.Limited) {
                            accounts[userAddresses[i]].positions[positionName].dcaIterations -= 1;
                            console.log("else2!!!!!!!!!");
                        }
                        accounts[userAddresses[i]].positions[positionName].SwappedToBalance += resultSwap;
                        accounts[userAddresses[i]].positions[positionName].SwappedFromBalance += position.amountPerSwap;
                        accounts[userAddresses[i]].positions[positionName].status = Status.Active;
                        accounts[userAddresses[i]].positions[positionName].lastPurchaseTimestamp = block.timestamp;
                        console.log("else3!!!!!!!!!");
                        emit DCAExecuted(
                            userAddresses[i],
                            positionName,
                            address(inputToken),
                            address(outputToken),
                            position.amountPerSwap,
                            resultSwap,
                            block.timestamp
                        );
                        console.log("else4!!!!!!!!!");
                    }
                }
            }
        }
    }

    function _swap(uint256 _amount, address _receiver) internal returns (uint256) {
        require(inputToken.balanceOf(address(this)) > _amount, "Insufficient balance of origin Token");

        inputToken.approve(address(swapRouter), _amount);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: address(inputToken),
            tokenOut: address(outputToken),
            fee: 3000,
            recipient: _receiver,
            deadline: block.timestamp + 1800,
            amountIn: _amount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        if (_amount != 0) {
            return swapRouter.exactInputSingle(params);
        } else {
            return 0;
        }
    }

    // don't forget to add a removing for approve ( for example mister T approved 1000 USD but stop position after 800 USD. We need to remove 200 USD of allowance)
    function _closePosition(address _user, string calldata _name) internal {
        accounts[_user].positions[_name].status = Status.Closed;
        accounts[_user].closedPositionsKeys.push(_name);
        accounts[_user].closedPositions[_name] = accounts[_user].positions[_name];
        delete(accounts[_user].positions[_name]);
        uint256 posKeysLength = accounts[_user].positionsKeys.length;
        for (uint256 i = 0; i < posKeysLength; i++) {
            string memory _key = accounts[_user].positionsKeys[i];
            if (keccak256(abi.encodePacked(_name)) == keccak256(abi.encodePacked(_key))) {
                accounts[_user].positionsKeys[i] = accounts[_user].positionsKeys[posKeysLength - 1];
                accounts[_user].positionsKeys.pop();
                break;
            }
        }
        emit PositionStatusChanged(
            _user, address(inputToken), address(outputToken), _name, Status.Closed, block.timestamp
        );
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
        require(accounts[msg.sender].positions[_name].createdTimestamp == 0, "Position is already existing");
        require(_interval >= 3, "this interval is not allowed"); // in production mode 86400
        require(_totalAmountToSwap > 0, "No amount set for DCA");
        require(
            (_amountPerSwap == 0 && _dcaIterations != 0) || (_amountPerSwap != 0 && _dcaIterations == 0),
            "Set only amount per swap or number of iterations"
        );

        console.log("pouuuuuuuuuuuuuuuuuuet!!!!!!!!!");

        // uint256 totalToSwapAfterFees = _totalAmountToSwap - (_totalAmountToSwap * depositFee / 10000);
        uint256 amountPerSwap =
            _amountPerSwap > 0 ? _amountPerSwap : ((_totalAmountToSwap * 10000) / _dcaIterations) / 10000;

        //SafeERC20.safeTransferFrom(inputToken, msg.sender, address(this), _totalAmountToSwap);
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

        accounts[msg.sender].positionsKeys.push(_name);

        emit PositionCreated(msg.sender, address(inputToken), address(outputToken), _name, block.timestamp);
    }

    /**
     * @dev Set the status of a user's position.
     * @param _name The name of the position to update.
     * @param _status The new status of the position.
     * Emits a {PositionStatusChanged} event.
     * Requirements:
     * - The position must exist.
     */
    function setPositionStatus(string calldata _name, Status _status) external positionExists(_name) {
        accounts[msg.sender].positions[_name].status = _status;
        emit PositionStatusChanged(
            msg.sender, address(inputToken), address(outputToken), _name, Status.Pause, block.timestamp
        );
    }

    /**
     * @dev Close a position and transfer any remaining tokens back to the user's wallet.
     * @param _name The ID of the position to close.
     * Requirements:
     * - The position must exist.
     * - The position must not be locked.
     */
    function closePosition(string calldata _name) external positionExists(_name) {
        _closePosition(msg.sender, _name);
    }

    /**
     * @dev Claim all fees collected by the contract.
     * Requirements:
     * - The caller must be the contract owner.
     */
    function claimFees() external onlyOwner returns (uint256 fees) {
        fees = feesBalances[inputToken];
        if (inputToken.balanceOf(address(this)) >= fees) {
            SafeERC20.safeTransfer(inputToken, msg.sender, fees);
            feesBalances[inputToken] = 0;
        } else {
            revert("No sufficient funds on contract to get fees");
        }
    }

    /**
     * @dev Get a position by name.
     * @param _name The name of the position to get.
     * @return The position object.
     */
    function getPosition(string calldata _name) external view returns (Position memory) {
        return accounts[msg.sender].positions[_name];
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
