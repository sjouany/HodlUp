// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "../node_modules/@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
//import "../node_modules/@ganache/console.log/console.sol";

using SafeERC20 for IERC20;

/**
 * @title DcaHodlup
 * @notice A contract for DCA investment strategy with swapping functionality.
 * @dev This contract allows users to create DCA positions and execute periodic swaps using a Uniswap router.
 * @dev Users can create, manage, and close DCA positions, and the owner can execute swaps and claim fees.
 */
contract DcaHodlup is Ownable {
    /**
     * @dev Enum representing the possible status of a DCA position.
     */
    enum Status {
        Active,
        Pause,
        Closed,
        Locked
    }
    /**
     * @dev Enum representing the DCA mode (Limited or Unlimited) for a position.
     */
    enum DcaMode {
        Limited,
        Unlimited
    }

    IERC20 inputToken;
    IERC20 outputToken;

    ISwapRouter swapRouter;

    struct Account {
        mapping(string => Position) positions;
        string[] positionsKeys;
        mapping(string => Position) closedPositions;
        string[] closedPositionsKeys;
    }

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

    mapping(address => Account) accounts;
    address[] public userAddresses;
    mapping(IERC20 => uint256) feesBalances;
    uint256 public swapFee;
    uint256 private currentUserindex;
    uint256 private operationsLimit;

    /**
     * @dev Initializes the contract with the specified parameters.
     * @param _inputToken Address of the input token for swaps.
     * @param _outputToken Address of the output token for swaps.
     * @param _uniswapRouter Address of the Uniswap router.
     * @param _swapFee The swap fee percentage.
     */
    function initialize(address _inputToken, address _outputToken, address _uniswapRouter, uint256 _swapFee) public {
        require(address(inputToken) == address(0), "Contract has already been initialized");
        inputToken = IERC20(_inputToken);
        outputToken = IERC20(_outputToken);
        swapRouter = ISwapRouter(_uniswapRouter);
        swapFee = _swapFee;
    }

    /**
     * @dev Event emitted when a new DCA position is created.
     * @param sender The address of the sender.
     * @param token_from The address of the input token.
     * @param token_to The address of the output token.
     * @param name The name of the DCA position.
     * @param date The timestamp of the event.
     */
    event PositionCreated(address indexed sender, address token_from, address token_to, string name, uint256 date);

    /**
     * @dev Event emitted when the status of a DCA position is changed.
     * @param sender The address of the sender.
     * @param token_from The address of the input token.
     * @param token_to The address of the output token.
     * @param name The name of the DCA position.
     * @param status The new status of the DCA position.
     * @param date The timestamp of the event.
     */
    event PositionStatusChanged(
        address indexed sender, address token_from, address token_to, string name, Status status, uint256 date
    );

    /**
     * @dev Event emitted when a DCA is executed.
     * @param user The address of the user.
     * @param name The name of the DCA position.
     * @param token_from The address of the input token.
     * @param token_to The address of the output token.
     * @param amountToSwap The amount to swap.
     * @param amountSwapped The amount swapped.
     * @param date The timestamp of the event.
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

    /**
     * @dev Modifier to check if a DCA position exists.
     * @param _positionName The name of the DCA position.
     */
    modifier positionExists(string memory _positionName) {
        _positionExists(_positionName);
        _;
    }

    /**
     * @dev Checks if a DCA position with a given name exists for the caller.
     * @param _positionName The name of the DCA position to check.
     */
    function _positionExists(string memory _positionName) internal view {
        require(accounts[msg.sender].positions[_positionName].createdTimestamp > 0, "Position doesn't exist");
    }

    /**
     * @dev Checks if a user account exists based on the presence of DCA positions.
     * @param _userAddress The address of the user to check.
     * @return True if the user account exists, false otherwise.
     */
    function _userExists(address _userAddress) internal view returns (bool) {
        return
            (accounts[_userAddress].positionsKeys.length > 0 || accounts[_userAddress].closedPositionsKeys.length > 0);
    }

    /**
     * @dev Executes Dollar-Cost Averaging (DCA) swaps for all active positions of all users.
     * @dev This function iterates through user accounts and their DCA positions, executing swaps as necessary.
     * @dev It checks the status and timing of each position to determine if a swap should be executed.
     */
    function _executeIndividualDCA() internal {
        for (uint256 i = 0; i < userAddresses.length; i++) {
            Account storage account = accounts[userAddresses[i]];
            uint256 posKeysLength = account.positionsKeys.length;

            for (uint256 j = 0; j < posKeysLength; j++) {
                string memory positionName = account.positionsKeys[j];
                Position storage position = account.positions[positionName];

                if (
                    position.status == Status.Active
                        && block.timestamp > (position.lastPurchaseTimestamp + position.interval)
                ) {
                    uint256 remainingToSwap = position.totalAmountToSwap - position.SwappedFromBalance;

                    if (position.amountPerSwap > remainingToSwap) {
                        position.status = Status.Pause;
                        emit PositionStatusChanged(
                            userAddresses[i],
                            address(inputToken),
                            address(outputToken),
                            positionName,
                            Status.Pause,
                            block.timestamp
                        );
                    } else {
                        position.status = Status.Locked;
                        uint256 swapAmount = position.amountPerSwap;
                        SafeERC20.safeTransferFrom(inputToken, userAddresses[i], address(this), swapAmount);

                        uint256 swapFees = (swapAmount * swapFee) / 10000;
                        uint256 amountPerSwapAfterFees = swapAmount - swapFees;
                        uint256 resultSwap = _swap(amountPerSwapAfterFees, position.recipient);

                        feesBalances[inputToken] += swapFees;

                        if (position.mode == DcaMode.Limited) {
                            position.dcaIterations -= 1;
                        }

                        position.SwappedToBalance += resultSwap;
                        position.SwappedFromBalance += swapAmount;
                        position.status = Status.Active;
                        position.lastPurchaseTimestamp = block.timestamp;

                        emit DCAExecuted(
                            userAddresses[i],
                            positionName,
                            address(inputToken),
                            address(outputToken),
                            swapAmount,
                            resultSwap,
                            block.timestamp
                        );
                    }
                }
            }
        }
    }

    /**
     * @dev Executes a token swap operation using the Uniswap router.
     * @param _amount The amount of the input token to swap.
     * @param _receiver The address to receive the swapped tokens.
     * @return The amount of output tokens received from the swap.
     * @notice This function swaps a specified amount of the input token for output tokens
     * using the Uniswap router. It checks the balance of the input token to ensure sufficient funds,
     * approves the router to spend the input token, and sets the swap parameters.
     */
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

    /**
     * @dev Closes a Dollar-Cost Averaging (DCA) position for a user.
     * @param _user The address of the user who owns the DCA position.
     * @param _name The name of the DCA position to be closed.
     * @notice This function closes a DCA position by updating its status to 'Closed', moving it
     * to the 'closedPositions' mapping, and removing it from the 'positions' mapping for the specified user.
     * Additionally, it updates the user's list of DCA position keys and emits an event to indicate the closure.
     */
    function _closePosition(address _user, string calldata _name) internal {
        // don't forget to add a removing for approve ( for example mister T approved 1000 USD but stop position after 800 USD. We need to remove 200 USD of allowance)
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
     * @dev Creates a new DCA position.
     * @param _name The name of the DCA position.
     * @param _totalAmountToSwap The total amount to swap.
     * @param _interval The swap interval.
     * @param _amountPerSwap The amount to swap per interval.
     * @param _dcaIterations The number of DCA iterations.
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
     * @dev Sets the status of a DCA position.
     * @param _name The name of the DCA position.
     * @param _status The new status of the DCA position.
     */
    function setPositionStatus(string calldata _name, Status _status) external positionExists(_name) {
        accounts[msg.sender].positions[_name].status = _status;
        emit PositionStatusChanged(
            msg.sender, address(inputToken), address(outputToken), _name, Status.Pause, block.timestamp
        );
    }

    /**
     * @dev Closes a DCA position.
     * @param _name The name of the DCA position.
     */
    function closePosition(string calldata _name) external positionExists(_name) {
        _closePosition(msg.sender, _name);
    }

    /**
     * @dev Claims accumulated fees.
     * @return fees The fees claimed.
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
     * @dev Retrieves the details of a DCA position for the caller.
     * @param _name The name of the DCA position to retrieve.
     * @return Position struct containing position details.
     */
    function getPosition(string calldata _name) external view returns (Position memory) {
        return accounts[msg.sender].positions[_name];
    }

    /**
     * @dev Executes swaps for all active DCA positions of all users.
     * @dev Only the contract owner can execute this function.
     */
    function executeSwap() external onlyOwner {
        _executeIndividualDCA();
    }
}
