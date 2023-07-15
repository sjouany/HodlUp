// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./DcaHodlup.sol";

contract HodlupManager {
    mapping(bytes32 => address) public dcaContracts;

    function createDca(string memory _name, address _tokenFrom, address _tokenTo) public {
        bytes32 salt = keccak256(abi.encodePacked(_name, _tokenFrom, _tokenTo));
        bytes memory bytecode = type(DcaHodlup).creationCode;
        address dcaContract;

        assembly {
            dcaContract := create2(0, add(bytecode, 32), mload(bytecode), salt)
            if iszero(extcodesize(dcaContract)) {
                revert(0, 0)
            }
        }

        DcaHodlup(dcaContract).initialize(_name, _tokenFrom, _tokenTo);

        dcaContracts[salt] = dcaContract;
    }
}



