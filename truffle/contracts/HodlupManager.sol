// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./DcaHodlup.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
//import "../node_modules/@ganache/console.log/console.sol";

/**
 * @title HodlupManager
 * @notice A contract for managing DCA (Dollar-Cost Averaging) pairs and their operations.
 * @dev This contract allows the owner to create and manage multiple DCA pairs and execute operations on them.
 */
contract HodlupManager is Ownable {
    mapping(string => address) public dcaContracts;
    string[] dcaContractsNames;

    /**
     * @dev Emitted when a new DCA pair is created.
     * @param _name The name of the DCA pair.
     * @param _contractAddress The address of the DCA pair contract.
     * @param _timestamp The timestamp when the DCA pair was created.
     */
    event DcaCreated(string _name, address _contractAddress, uint256 _timestamp);

    /**
     * @dev Creates a new DCA pair contract.
     * @param _name The name of the DCA pair.
     * @param _tokenFrom Address of the input token for swaps.
     * @param _tokenTo Address of the output token for swaps.
     * @param _uniswapRouter Address of the Uniswap router.
     * @param _fee The swap fee percentage.
     * @return dcaContract The address of the created DCA pair contract.
     * @notice This function creates a new DCA pair contract using the create2 method.
     */
    function createDcaPaire(
        string memory _name,
        address _tokenFrom,
        address _tokenTo,
        address _uniswapRouter,
        uint256 _fee
    ) external onlyOwner returns (address dcaContract) {
        bytes32 salt = keccak256(abi.encodePacked(_name));
        bytes memory bytecode = type(DcaHodlup).creationCode;

        assembly {
            dcaContract := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(dcaContract)) { revert(0, 0) }
        }
        //console.logAddress(dcaContract);
        DcaHodlup(dcaContract).initialize(_tokenFrom, _tokenTo, _uniswapRouter, _fee);

        dcaContracts[_name] = dcaContract;
        dcaContractsNames.push(_name);
        emit DcaCreated(_name, dcaContract, block.timestamp);
    }

    /**
     * @dev Withdraws fees from a DCA pair contract.
     * @param contractName The name of the DCA pair contract.
     * @return fees The amount of fees withdrawn.
     * @notice This function allows the owner to withdraw fees from a specific DCA pair contract.
     */
    function withdrawFees(string memory contractName) public onlyOwner returns (uint256) {
        return DcaHodlup(dcaContracts[contractName]).claimFees();
    }

    /**
     * @dev Withdraws all fees from all DCA pair contracts.
     * @return totalFees The total amount of fees withdrawn from all contracts.
     * @notice This function allows the owner to withdraw all fees from all DCA pair contracts.
     */
    function withdrawAllFees() external onlyOwner returns (uint256 totalFees) {
        uint256 dcaContNamesLength = dcaContractsNames.length;
        for (uint256 j = 0; j < dcaContNamesLength; j++) {
            string memory name = dcaContractsNames[j];
            totalFees = totalFees + withdrawFees(name);
        }
    }

    /**
     * @dev Executes swaps for a specific DCA pair contract.
     * @param contractName The name of the DCA pair contract.
     * @notice This function allows the owner to execute swaps for a specific DCA pair contract.
     */
    function executeSwap(string memory contractName) public onlyOwner {
        DcaHodlup(dcaContracts[contractName]).executeSwap();
    }

    /**
     * @dev Executes swaps for all DCA pair contracts.
     * @notice This function allows the owner to execute swaps for all DCA pair contracts.
     */
    function executeAllSwap() public onlyOwner {
        uint256 dcaContNamesLength = dcaContractsNames.length;
        for (uint256 j = 0; j < dcaContNamesLength; j++) {
            string memory name = dcaContractsNames[j];
            executeSwap(name);
        }
    }
}
