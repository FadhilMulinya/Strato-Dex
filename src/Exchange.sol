// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import './ERC20.sol';
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title TokenSwapExchange Contract
 * @dev This contract implements a decentralized exchange for swapping tokens and ETH, adding/removing liquidity, and tracking reserves.
 * It inherits from ERC20 and ReentrancyGuard for token functionality and protection against reentrancy attacks.
 */
contract TokenSwapExchange is ERC20, ReentrancyGuard {
    
    // Variables
    address immutable tokenAddress;  // The address of the ERC-20 token being traded in this exchange
    address immutable factoryAddress; // The address of the contract's factory or creator

    // Events
    event LiquidityDeposited(address indexed provider, uint ethAmount, uint tokenAmount);  // Emitted when liquidity is added
    event LiquidityWithdrawn(address indexed provider, uint ethAmount, uint tokenAmount);  // Emitted when liquidity is removed
    event TokensPurchased(address indexed buyer, uint ethAmount, uint tokensReceived);  // Emitted when tokens are purchased
    event TokensSold(address indexed seller, uint tokensSold, uint ethReceived);  // Emitted when tokens are sold

    /**
     * @dev Constructor to initialize the contract with the token address.
     * @param _tokenAddress The address of the ERC-20 token to be used in the exchange
     */
    constructor(address _tokenAddress) ERC20("STRATO", "STR") {
        require(_tokenAddress != address(0), "Token address cannot be 0x0");
        tokenAddress = _tokenAddress;
        factoryAddress = msg.sender;  // The contract deployer is the factory address
    }

    /**
     * @dev Returns the balance of tokens held by the contract.
     * @return The amount of tokens in the exchange contract
     */
    function fetchTokenReserves() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    // Pricing Functions

    /**
     * @dev Given an amount of ETH sold, returns the corresponding amount of tokens that can be bought.
     * @param ethSold The amount of ETH being sold
     * @return The number of tokens the seller will receive
     */
    function calculateTokensForETH(uint ethSold) public view returns (uint256) {
        require(ethSold > 0, "ETH sold must be greater than 0");
        uint outputReserve = fetchTokenReserves(); // Reserve of tokens in the exchange
        return calculateSwapAmount(ethSold, address(this).balance - ethSold, outputReserve);
    }

    /**
     * @dev Given an amount of tokens sold, returns the corresponding amount of ETH that can be received.
     * @param tokensSold The amount of tokens being sold
     * @return The amount of ETH the seller will receive
     */
    function calculateETHForTokens(uint tokensSold) public view returns (uint256) {
        require(tokensSold > 0, "Tokens sold must be greater than 0");
        uint inputReserve = fetchTokenReserves(); // Reserve of tokens in the exchange
        return calculateSwapAmount(tokensSold, inputReserve - tokensSold, address(this).balance);
    }

    /**
     * @dev Utility function to calculate the amount of tokens or ETH based on input amounts and reserves.
     * @param inputAmount The amount of input (ETH or tokens) to be swapped
     * @param inputReserve The current balance of the input asset (ETH or tokens) in the exchange
     * @param outputReserve The current balance of the output asset (tokens or ETH) in the exchange
     * @return The amount of output asset (tokens or ETH) the user will receive
     */
    function calculateSwapAmount(uint inputAmount, uint inputReserve, uint outputReserve) public pure returns (uint256) {
        require(inputReserve > 0 && inputAmount > 0, "Invalid values provided");
        uint256 inputAmountWithFee = inputAmount * 997;  // Accounting for a 0.3% fee
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 1000) + inputAmountWithFee;
        return numerator / denominator;
    }

    // Liquidity Functions

    /**
     * @dev Allows users to add liquidity to the exchange by providing both ETH and tokens.
     * @param tokensAdded The amount of tokens being added to the liquidity pool
     * @return The amount of liquidity tokens minted for the user
     */
    function depositLiquidity(uint tokensAdded) external payable nonReentrant returns (uint256) {
        require(msg.value > 0 && tokensAdded > 0, "Invalid values provided");

        uint ethBalance = address(this).balance;
        uint tokenBalance = fetchTokenReserves();

        if (tokenBalance == 0) {
            require(IERC20(tokenAddress).balanceOf(msg.sender) >= tokensAdded, "Insufficient token balance");
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokensAdded);
            uint liquidity = ethBalance;
            _mint(msg.sender, liquidity);
            emit LiquidityDeposited(msg.sender, msg.value, tokensAdded);
            return liquidity;
        } else {
            uint liquidity = (msg.value * totalSupply()) / (ethBalance - msg.value);
            require(IERC20(tokenAddress).balanceOf(msg.sender) >= tokensAdded, "Insufficient token balance");
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokensAdded);
            _mint(msg.sender, liquidity);
            emit LiquidityDeposited(msg.sender, msg.value, tokensAdded);
            return liquidity;
        }
    }

    /**
     * @dev Allows users to remove liquidity from the exchange and withdraw both ETH and tokens.
     * @param tokenAmount The amount of liquidity tokens the user wants to redeem
     * @return The amount of ETH and tokens withdrawn by the user
     */
    function withdrawLiquidity(uint256 tokenAmount) external nonReentrant returns(uint, uint) {
        require(tokenAmount > 0, "Invalid token amount");

        uint ethAmount = (address(this).balance * tokenAmount) / totalSupply();
        uint tokenAmt = (fetchTokenReserves() * tokenAmount) / totalSupply();

        require((fetchTokenReserves() / address(this).balance) == ((fetchTokenReserves() + tokenAmt) / (address(this).balance + ethAmount)), "Invariant check failed");
        _burn(msg.sender, tokenAmount);

        payable(msg.sender).transfer(ethAmount);
        IERC20(tokenAddress).transfer(msg.sender, tokenAmt);

        emit LiquidityWithdrawn(msg.sender, ethAmount, tokenAmt);

        return (ethAmount, tokenAmt);
    }

    // Swap Functions

    /**
     * @dev Allows users to swap ETH for tokens in the exchange.
     * @param minTokens The minimum number of tokens the user is willing to accept
     * @param recipient The address of the recipient to receive the tokens
     * @return The amount of tokens received by the user
     */
    function purchaseTokensWithETH(uint minTokens, address recipient) external payable nonReentrant returns (uint) {
        uint tokenAmount = calculateTokensForETH(msg.value);
        require(tokenAmount >= minTokens, "Token amount less than expected");

        IERC20(tokenAddress).transfer(recipient, tokenAmount);
        emit TokensPurchased(msg.sender, msg.value, tokenAmount);

        return tokenAmount;
    }

    /**
     * @dev Allows users to swap tokens for ETH in the exchange.
     * @param tokensSold The amount of tokens the user is selling
     * @param minEth The minimum amount of ETH the user is willing to receive
     * @return The amount of ETH the user receives
     */
    function sellTokensForETH(uint tokensSold, uint minEth) external nonReentrant returns(uint) {
        uint ethAmount = calculateETHForTokens(tokensSold);
        require(ethAmount >= minEth, "ETH amount less than expected");

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokensSold);
        payable(msg.sender).transfer(ethAmount);
        emit TokensSold(msg.sender, tokensSold, ethAmount);

        return ethAmount;
    }
}
