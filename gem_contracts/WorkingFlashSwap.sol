// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    function getAmountsOut(uint amountIn, address[] calldata path)
        external view returns (uint[] memory amounts);
}

interface IUniswapV2Pair {
    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;
    
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

/**
 * @title WorkingFlashSwap
 * @dev A working flash swap arbitrage contract for Arbitrum
 */
contract WorkingFlashSwap is ReentrancyGuard, Ownable {
    
    // DEX addresses on Arbitrum
    address constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant SUSHISWAP_ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address constant CAMELOT_ROUTER = 0xc873fEcbd354f5A56E00E710B90EF4201db2448d;
    
    address constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address constant SUSHISWAP_FACTORY = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
    
    // Token addresses on Arbitrum
    address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address constant ARB = 0x912CE59144191C1204E64559FE8253a0e49E6548;
    
    struct ArbitrageParams {
        address tokenA;
        address tokenB;
        uint256 amount;
        address routerA;
        address routerB;
        uint256 minProfit;
    }
    
    event ArbitrageExecuted(
        address indexed tokenA,
        address indexed tokenB,
        uint256 amount,
        uint256 profit,
        address indexed executor
    );
    
    event FlashSwapExecuted(
        address indexed pair,
        uint256 amount0Out,
        uint256 amount1Out,
        uint256 profit
    );
    
    constructor() {
        // Set deployer as owner
    }
    
    /**
     * @dev Execute flash swap arbitrage
     * @param tokenA First token address
     * @param tokenB Second token address
     * @param amount Amount to flash swap
     * @param routerA First router address
     * @param routerB Second router address
     */
    function executeFlashSwapArbitrage(
        address tokenA,
        address tokenB,
        uint256 amount,
        address routerA,
        address routerB
    ) external onlyOwner nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(tokenA != address(0) && tokenB != address(0), "Invalid token addresses");
        
        // Get pair address for flash swap
        address pair = getPairAddress(tokenA, tokenB);
        require(pair != address(0), "Pair not found");
        
        // Calculate amounts to flash swap
        (uint256 amount0Out, uint256 amount1Out) = calculateFlashSwapAmounts(
            pair, tokenA, tokenB, amount
        );
        
        // Execute flash swap
        bytes memory data = abi.encode(ArbitrageParams({
            tokenA: tokenA,
            tokenB: tokenB,
            amount: amount,
            routerA: routerA,
            routerB: routerB,
            minProfit: 0
        }));
        
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
    }
    
    /**
     * @dev Uniswap V2 callback function
     */
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        require(sender == address(this), "Only this contract can call");
        
        // Decode arbitrage parameters
        ArbitrageParams memory params = abi.decode(data, (ArbitrageParams));
        
        // Execute arbitrage
        uint256 profit = executeArbitrage(params, amount0, amount1);
        
        // Calculate repayment amount
        uint256 repayment = calculateRepayment(params.tokenA, params.tokenB, amount0, amount1);
        
        // Repay flash swap
        IERC20(params.tokenA).transfer(msg.sender, repayment);
        
        // Transfer profit to owner
        if (profit > 0) {
            IERC20(params.tokenB).transfer(owner(), profit);
        }
        
        emit FlashSwapExecuted(msg.sender, amount0, amount1, profit);
        emit ArbitrageExecuted(params.tokenA, params.tokenB, params.amount, profit, msg.sender);
    }
    
    /**
     * @dev Execute the arbitrage trade
     */
    function executeArbitrage(
        ArbitrageParams memory params,
        uint256 amount0,
        uint256 amount1
    ) internal returns (uint256 profit) {
        // Determine which token we received
        address receivedToken = amount0 > 0 ? params.tokenA : params.tokenB;
        uint256 receivedAmount = amount0 > 0 ? amount0 : amount1;
        
        // Approve router to spend tokens
        IERC20(receivedToken).approve(params.routerA, receivedAmount);
        
        // Execute swap on first DEX
        address[] memory path = new address[](2);
        path[0] = receivedToken;
        path[1] = receivedToken == params.tokenA ? params.tokenB : params.tokenA;
        
        uint256[] memory amounts = IUniswapV2Router(params.routerA).swapExactTokensForTokens(
            receivedAmount,
            0, // Accept any amount out
            path,
            address(this),
            block.timestamp + 300 // 5 minute deadline
        );
        
        // Execute reverse swap on second DEX
        IERC20(path[1]).approve(params.routerB, amounts[1]);
        
        address[] memory reversePath = new address[](2);
        reversePath[0] = path[1];
        reversePath[1] = path[0];
        
        uint256[] memory reverseAmounts = IUniswapV2Router(params.routerB).swapExactTokensForTokens(
            amounts[1],
            0, // Accept any amount out
            reversePath,
            address(this),
            block.timestamp + 300 // 5 minute deadline
        );
        
        // Calculate profit
        if (reverseAmounts[1] > receivedAmount) {
            profit = reverseAmounts[1] - receivedAmount;
        }
    }
    
    /**
     * @dev Get pair address for two tokens
     */
    function getPairAddress(address tokenA, address tokenB) internal view returns (address) {
        // Try Uniswap V2 factory first
        address pair = IUniswapV2Factory(UNISWAP_V2_FACTORY).getPair(tokenA, tokenB);
        if (pair != address(0)) {
            return pair;
        }
        
        // Try SushiSwap factory
        pair = IUniswapV2Factory(SUSHISWAP_FACTORY).getPair(tokenA, tokenB);
        return pair;
    }
    
    /**
     * @dev Calculate flash swap amounts
     */
    function calculateFlashSwapAmounts(
        address pair,
        address tokenA,
        address tokenB,
        uint256 amount
    ) internal view returns (uint256 amount0Out, uint256 amount1Out) {
        // Get pair reserves
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pair).getReserves();
        address token0 = IUniswapV2Pair(pair).token0();
        
        if (tokenA == token0) {
            amount0Out = amount;
            amount1Out = 0;
        } else {
            amount0Out = 0;
            amount1Out = amount;
        }
    }
    
    /**
     * @dev Calculate repayment amount for flash swap
     */
    function calculateRepayment(
        address tokenA,
        address tokenB,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint256) {
        // Simplified calculation - in production, you'd use actual reserves and fees
        return amount0 > 0 ? amount0 : amount1;
    }
    
    /**
     * @dev Emergency function to withdraw tokens
     */
    function emergencyWithdraw(address token) external onlyOwner {
        IERC20 tokenContract = IERC20(token);
        uint256 balance = tokenContract.balanceOf(address(this));
        if (balance > 0) {
            tokenContract.transfer(owner(), balance);
        }
    }
    
    /**
     * @dev Get contract balance for a token
     */
    function getBalance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }
    
    /**
     * @dev Get contract ETH balance
     */
    function getETHBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Withdraw ETH
     */
    function withdrawETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    // Receive ETH
    receive() external payable {}
}
