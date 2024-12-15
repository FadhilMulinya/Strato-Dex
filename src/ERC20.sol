// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title StratoToken Contract
 * @dev This contract implements an ERC-20 token called STRATO with an initial supply minted to the deployer's address.
 *      The contract also allows the owner to mint additional tokens.
 */
contract StratoToken is ERC20, Ownable {

    /**
     * @dev Constructor that initializes the STRATO token with a total supply of 3,000,000,000 tokens.
     *      The total supply is minted to the owner's address.
     * @param initialOwner The address of the initial owner, typically the deployer's address.
     */
    constructor(address initialOwner) ERC20("STRATO", "STR") Ownable(initialOwner){
        // Mint 3,000,000,000 STRATO tokens (using 18 decimal places for precision)
        _mint(msg.sender, 3_000_000_000e18);  
    }

    /**
     * @dev Allows the owner of the contract to mint new STRATO tokens.
     * @param account The address to receive the newly minted tokens.
     * @param amount The amount of STRATO tokens to mint (in smallest units, e.g., wei).
     */
    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);  // Mint the specified amount of STRATO tokens to the provided address
    }
}
