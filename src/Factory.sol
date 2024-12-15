// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "./Exchange.sol";

/**
 * @title Factory Contract
 * @dev This contract manages the creation of new exchanges for different ERC-20 tokens.
 * It maps token addresses to their respective exchange contracts and provides functions to create and retrieve exchanges.
 */
contract Factory {

    // Variables
    uint256 public tokenCount;  // The count of created token exchanges
    mapping(address => address) public tokenToExchange;  // Mapping from token address to exchange address
    mapping(address => address) public exchangeToToken;  // Mapping from exchange address to token address
    mapping(uint256 => address) public idToToken;  // Mapping from token ID to token address
    TokenSwapExchange[] public exchangeArray;  // Array to store all created exchange contracts

    // Events
    event ExchangeCreated(address indexed tokenAddress, address indexed exchangeAddress);  // Emitted when a new exchange is created

    /**
     * @dev Creates a new exchange for a specific token.
     * @param _tokenAddress The address of the ERC-20 token for which the exchange is being created
     * @return The address of the newly created exchange contract
     */
    function createExchangeForToken(address _tokenAddress) public returns(address) {
        require (_tokenAddress != address(0), "Invalid token address");  // Ensures the provided token address is valid
        require(tokenToExchange[_tokenAddress] == address(0), "Exchange already exists");  // Checks that an exchange doesn't already exist for the token

        // Create a new exchange contract for the token
        TokenSwapExchange exchange = new TokenSwapExchange(_tokenAddress);

        // Store the exchange in the mapping and array
        exchangeArray.push(exchange);
        tokenToExchange[_tokenAddress] = address(exchange);
        tokenCount++;  // Increment the count of created exchanges

        // Emit an event for the newly created exchange
        emit ExchangeCreated(_tokenAddress, address(exchange));

        return address(exchange);  // Return the address of the created exchange contract
    }

    /**
     * @dev Returns the address of the exchange for a specific token.
     * @param _tokenAddress The address of the token for which the exchange address is being queried
     * @return The address of the exchange contract associated with the token
     */
    function fetchExchangeForToken(address _tokenAddress) public view returns(address) {
        return tokenToExchange[_tokenAddress];  // Retrieve the exchange address for the token
    }

    /**
     * @dev Returns the address of the token associated with a specific exchange.
     * @param _exchange The address of the exchange contract for which the token address is being queried
     * @return The address of the token associated with the exchange
     */
    function fetchTokenForExchange(address _exchange) public view returns (address) {
        return exchangeToToken[_exchange];  // Retrieve the token address for the exchange
    }

    /**
     * @dev Returns the address of the token given its ID.
     * @param _tokenId The ID of the token for which the address is being queried
     * @return The address of the token with the specified ID
     */
    function fetchTokenById(uint256 _tokenId) public view returns (address) {
        return idToToken[_tokenId];  // Retrieve the token address for the given token ID
    }
}
