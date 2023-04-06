// Dai.sol
pragma solidity 0.8.18;
 
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
 
contract Hodl is ERC20, Ownable {
	constructor() ERC20('Hodl', 'HODL') {} 
 
	function provide(address recipient, uint nbtoken) external onlyOwner {
		_mint(recipient, nbtoken * 10 ** decimals());
	}
}