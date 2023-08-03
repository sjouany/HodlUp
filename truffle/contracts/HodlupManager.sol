// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./DcaHodlup.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract HodlupManager is Ownable {
    mapping(string => address) public dcaContracts;
    string[] dcaContractsNames;

    event DcaCreated(string _name, address _contractAddress, uint256 _timestamp);

    function createDcaPaire(string memory _name, address _tokenFrom, address _tokenTo, address _uniswapRouter, uint256 _fee)
        external
        onlyOwner
        returns (address dcaContract)
    {
        bytes32 salt = keccak256(abi.encodePacked(_name));
        bytes memory bytecode = type(DcaHodlup).creationCode;

        assembly {
            dcaContract := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(dcaContract)) { revert(0, 0) }
        }

        DcaHodlup(dcaContract).initialize(_tokenFrom, _tokenTo, _uniswapRouter, _fee);

        dcaContracts[_name] = dcaContract;
        dcaContractsNames.push(_name);
        emit DcaCreated(_name, dcaContract, block.timestamp);
    }

    function withdrawFees(string memory contractName) public onlyOwner returns (uint256) {
        return DcaHodlup(dcaContracts[contractName]).claimFees();
    }

    function withdrawAllFees() external onlyOwner returns (uint256 totalFees) {
        uint256 dcaContNamesLength = dcaContractsNames.length;
        for (uint256 j = 0; j < dcaContNamesLength; j++) {
            string memory name = dcaContractsNames[j];
            totalFees = totalFees + withdrawFees(name);
        }
    }

    function executeSwap(string memory contractName) public onlyOwner {
        DcaHodlup(dcaContracts[contractName]).executeSwap();
    }

    
    function executeAllSwap() public onlyOwner {
        uint256 dcaContNamesLength = dcaContractsNames.length;
        for (uint256 j = 0; j < dcaContNamesLength; j++) {
            string memory name = dcaContractsNames[j];
            executeSwap(name);
        }
    }


    /// implementer le swap pour un contrat
    // le swap compter les positions
}
