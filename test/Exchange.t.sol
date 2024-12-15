// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

// Importing necessary contracts and libraries for testing
import "../src/Exchange.sol";
import "../src/ERC20.sol";
import "forge-std/Test.sol";

// Test contract for the Exchange contract
contract ExchangeTest is Test {
    // Declare variables for the Exchange contract, ERC20 token, and token address
    TokenSwapExchange exchange;
    StratoToken token;
    address tokenAddress;

    // Declare the address for the owner, using makeAddr for test address creation
    address owner = makeAddr("alice");

    // Setup function executed before each test
    function setUp() public {
        // Set the owner as the sender for token creation and approval
        vm.prank(owner);
        // Deploy a new ERC20 token with the owner as the initial owner
        token = new StratoToken(owner);
        // Set the token address for the exchange contract
        tokenAddress = address(token);
        // Deploy the Exchange contract using the deployed token address
        exchange = new TokenSwapExchange(tokenAddress);
    }

    // Test adding liquidity to the exchange
    function testAddLiquidity() public {
        // Set the owner as the sender for testing purposes
        vm.prank(owner);
        // Allocate 10 ether to the owner's balance for liquidity adding
        vm.deal(owner, 10 ether);

        // Mint 10,000 tokens for the owner
        token.mint(owner, 10000 * 10 ** 18);

        // Approve the exchange to spend the owner's tokens
        vm.prank(owner); 
        token.approve(address(exchange), 10000 * 10 ** 18);

        // Add liquidity to the exchange
        vm.prank(owner);
        uint256 tokensToAdd = 5000 * 10 ** 18; // Amount of tokens to add to the exchange
        uint256 ethToAdd = 10 ether; // Amount of ETH to add to the exchange
        uint256 liquidity = exchange.depositLiquidity{value: ethToAdd}(tokensToAdd);

        // Log liquidity minted and ensure it's greater than 0
        console.log(liquidity);
        assertGt(liquidity, 0, "Liquidity tokens not minted");

        // Verify that the exchange received the correct amount of tokens and ETH
        uint256 contractTokenBalance = token.balanceOf(address(exchange));
        assertEq(contractTokenBalance, tokensToAdd, "Exchange token balance incorrect");
        assertEq(address(exchange).balance, ethToAdd, "Exchange ETH balance incorrect");
    }

    // Test removing liquidity from the exchange
    function testRemoveLiquidity() public {
        // Set the owner as the sender and add liquidity to the exchange
        vm.prank(owner);
        vm.deal(owner, 10 ether);
        token.mint(owner, 10000 * 10 ** 18);
        vm.prank(owner);
        token.approve(address(exchange), 10000 * 10 ** 18);
        vm.prank(owner);
        uint256 tokensToAdd = 5000 * 10 ** 18;
        uint256 ethToAdd = 10 ether;
        uint256 liquidity = exchange.depositLiquidity{value: ethToAdd}(tokensToAdd);
    
        uint256 totalLiquidityTokens = liquidity;

        // Remove liquidity from the exchange
        vm.prank(owner);
        (uint ethAmount, uint tokenAmount) = exchange.withdrawLiquidity(totalLiquidityTokens);

        // Log the returned ETH and token amounts and verify correctness
        console.log(ethAmount, tokenAmount);
        assertTrue(ethAmount > 0 && tokenAmount > 0, "ETH and Tokens should be returned");
        assertEq(ethAmount, ethToAdd, "Incorrect ETH amount returned");
        assertEq(tokenAmount, tokensToAdd, "Incorrect Token amount returned");
    }

    // Test swapping ETH for tokens in the exchange
    function testSwapEthForTokens() public {
        // Set the owner as the sender and add liquidity to the exchange
        vm.prank(owner);
        vm.deal(owner, 10 ether);
        token.mint(owner, 10000 ether);
        vm.prank(owner);
        token.approve(address(exchange), 10000 ether);
        vm.prank(owner);
        exchange.depositLiquidity{value: 10 ether}(10000 ether);
    
        uint ethToSwap = 1 ether; // Amount of ETH to swap for tokens
        uint minTokens = 1; // Minimum number of tokens expected in the swap
        address recipient = makeAddr("bob"); // Create a recipient address for the swap
        vm.deal(recipient, ethToSwap); // Allocate ETH to the recipient for the swap

        // Perform the ETH to token swap and ensure the expected number of tokens is received
        vm.prank(recipient);
        uint tokensReceived = exchange.purchaseTokensWithETH{value: ethToSwap}(minTokens, recipient);
    
        assertTrue(tokensReceived >= minTokens, "Received less tokens than expected");
    }

    // Test swapping tokens for ETH in the exchange
    function testTokenForEthSwap() public {
        // Set the owner as the sender and add liquidity to the exchange
        vm.prank(owner);
        vm.deal(owner, 10 ether);
        token.mint(owner, 10000 ether);
        vm.prank(owner);
        token.approve(address(exchange), 10000 ether);
        vm.prank(owner);
        exchange.depositLiquidity{value: 10 ether}(10000 ether);
    
        address bob = makeAddr("bob");
        // Mint tokens for Bob and approve the exchange to spend them
        vm.prank(owner);
        token.mint(bob, 1000 ether);
        vm.prank(bob);
        token.approve(address(exchange), 1000 ether); 
    
        uint tokensToSwap = 500 ether; // Amount of tokens to swap for ETH
        uint minEth = 1; // Minimum amount of ETH expected in the swap
        vm.prank(bob);
        uint ethReceived = exchange.sellTokensForETH(tokensToSwap, minEth);

        // Ensure the expected amount of ETH is received in the token for ETH swap
        assertTrue(ethReceived >= minEth, "Received less ETH than expected");
    }
}
