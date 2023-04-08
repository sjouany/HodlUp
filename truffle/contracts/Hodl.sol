// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
 
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Hodl
 * @dev A token contract that mints new HODL tokens and allows the owner to transfer them to a specified recipient.
 */
contract Hodl is ERC20, Ownable {
	constructor() ERC20('Hodl', 'HODL') {} 
 
     /**
     * @dev Mints a specified amount of tokens to the specified recipient.
     * @param recipient The address to which the tokens will be minted.
     * @param nbtoken The number of tokens to mint.
     */
	function mint(address recipient, uint nbtoken) external onlyOwner {
		_mint(recipient, nbtoken * 10 ** decimals());
	}
}