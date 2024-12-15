// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

// Importing necessary libraries and contracts for testing
import "../lib/forge-std/src/Test.sol";
import "../src/Factory.sol";
import "../src/Exchange.sol";
import "../src/ERC20.sol";

// Test contract for the Factory contract
contract FactoryTest is Test {
    // Declare instances of the Factory and ERC20 token contracts
    Factory public factory;
    StratoToken public token;

    // Declare the address for the token owner using the makeAddr utility to generate an address
    address tokenOwner = makeAddr("owner");

    // Setup function that is executed before each test
    function setUp() public {
        // Deploy a new StratoToken contract with the specified tokenOwner address
        token = new StratoToken(tokenOwner);
        // Deploy a new Factory contract
        factory = new Factory();
    }

    // Test case for creating a new exchange in the Factory contract
    function testcreateExchangeForToken() public {
        // Create a new exchange for the token using the factory's createExchangeForToken method
        address tokenExchangeAddress = factory.createExchangeForToken(address(token));

        // Assert that the exchange address returned by the factory matches the expected address
        assertEq(factory.fetchExchangeForToken(address(token)), tokenExchangeAddress, "Exchange address does not match");

        // Assert that the exchange address is not 0x0, indicating the exchange was successfully created
        assertTrue(tokenExchangeAddress != address(0), "Exchange address should not be 0x0");
    }

    // Test case for attempting to create an exchange for an already existing token (should fail)
    function testFailCreateExchangeForExistingToken() public {
        // First, create a new exchange for the token
        factory.createExchangeForToken(address(token));
        
        // Attempt to create a new exchange for the same token again (this should fail)
        // The factory should prevent the creation of another exchange for the same token
        factory.createExchangeForToken(address(token));
    }
}
