// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title BalancerFlashLoanArbitrage
 * @notice Flash loan 100 ETH from Balancer (0% FEE!) and execute arbitrage
 * @dev Uses Balancer Vault for free flash loans on Arbitrum
 * 
 * KEY ADVANTAGE: Balancer charges 0% fee (vs Aave 0.05%)
 * Available liquidity: 755 WETH on Arbitrum
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Balancer V2 Interfaces
interface IBalancerVault {
    function flashLoan(
        address recipient,
        address[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

contract BalancerFlashLoanArbitrage is Ownable, ReentrancyGuard {
    
    // ============ STATE VARIABLES ============
    
    IBalancerVault public immutable balancerVault;
    
    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address public constant ARB = 0x912CE59144191C1204E64559FE8253a0e49E6548;
    
    // DEX Routers
    address public constant SUSHISWAP = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address public constant CAMELOT = 0xc873fEcbd354f5A56E00E710B90EF4201db2448d;
    address public constant UNISWAP = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    
    // Configuration
    uint256 public minProfitBasisPoints = 30; // 0.3% minimum profit
    bool public paused = false;
    
    // Stats
    uint256 public totalFlashLoans;
    uint256 public totalProfit;
    uint256 public totalVolume;
    
    // ============ EVENTS ============
    
    event FlashLoanExecuted(
        address indexed token,
        uint256 amount,
        uint256 profit,
        uint256 timestamp
    );
    
    event ArbitrageExecuted(
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 profit
    );
    
    event ProfitWithdrawn(
        address indexed token,
        uint256 amount,
        address indexed to
    );
    
    // ============ CONSTRUCTOR ============
    
    constructor(address _balancerVault) Ownable(msg.sender) {
        balancerVault = IBalancerVault(_balancerVault);
        
        // Approve routers
        IERC20(WETH).approve(SUSHISWAP, type(uint256).max);
        IERC20(WETH).approve(CAMELOT, type(uint256).max);
        IERC20(USDC).approve(SUSHISWAP, type(uint256).max);
        IERC20(USDC).approve(CAMELOT, type(uint256).max);
        IERC20(ARB).approve(SUSHISWAP, type(uint256).max);
        IERC20(ARB).approve(CAMELOT, type(uint256).max);
    }
    
    // ============ MAIN FLASH LOAN FUNCTION ============
    
    /**
     * @notice Initiate flash loan from Balancer (0% fee!)
     * @param token Token to borrow (WETH, ARB, etc)
     * @param amount Amount to borrow (can be up to 600 WETH!)
     */
    function executeFlashLoan(
        address token,
        uint256 amount
    ) external onlyOwner nonReentrant {
        require(!paused, "Contract paused");
        require(amount > 0, "Amount must be > 0");
        
        // Prepare flash loan
        address[] memory tokens = new address[](1);
        tokens[0] = token;
        
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        
        // Encode arbitrage parameters
        bytes memory userData = abi.encode(
            msg.sender,
            block.timestamp
        );
        
        // Execute flash loan (0% fee!)
        balancerVault.flashLoan(
            address(this),
            tokens,
            amounts,
            userData
        );
        
        totalFlashLoans++;
        totalVolume += amount;
    }
    
    // ============ BALANCER CALLBACK ============
    
    /**
     * @notice Balancer calls this function with borrowed tokens
     * @dev Must return exact borrowed amount (0% fee!)
     */
    function receiveFlashLoan(
        address[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external {
        require(msg.sender == address(balancerVault), "Only Balancer Vault");
        require(tokens.length == 1, "Single token only");
        
        address token = tokens[0];
        uint256 amount = amounts[0];
        uint256 fee = feeAmounts[0]; // Should be 0!
        
        require(fee == 0, "Expected 0% fee");
        
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        require(balanceBefore >= amount, "Insufficient balance");
        
        // ========== EXECUTE ARBITRAGE ==========
        
        uint256 profit = 0;
        
        if (token == WETH) {
            profit = _executeWETHArbitrage(amount);
        } else if (token == ARB) {
            profit = _executeARBArbitrage(amount);
        }
        
        // ========== VERIFY PROFIT ==========
        
        uint256 minProfit = (amount * minProfitBasisPoints) / 10000;
        require(profit >= minProfit, "Insufficient profit");
        
        // ========== REPAY FLASH LOAN ==========
        
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));
        require(balanceAfter >= amount, "Cannot repay loan");
        
        // Transfer exact amount back to Balancer (0% fee = exact amount!)
        IERC20(token).transfer(address(balancerVault), amount);
        
        totalProfit += profit;
        
        emit FlashLoanExecuted(token, amount, profit, block.timestamp);
    }
    
    // ============ ARBITRAGE STRATEGIES ============
    
    /**
     * @notice Execute WETH arbitrage loop
     * @dev WETH → USDC (DEX1) → WETH (DEX2)
     */
    function _executeWETHArbitrage(uint256 amount) internal returns (uint256 profit) {
        uint256 startBalance = IERC20(WETH).balanceOf(address(this));
        
        // Path 1: WETH → USDC on SushiSwap
        address[] memory path1 = new address[](2);
        path1[0] = WETH;
        path1[1] = USDC;
        
        IUniswapV2Router(SUSHISWAP).swapExactTokensForTokens(
            amount,
            0, // Accept any amount (will check profit after)
            path1,
            address(this),
            block.timestamp + 300
        );
        
        uint256 usdcBalance = IERC20(USDC).balanceOf(address(this));
        
        // Path 2: USDC → WETH on Camelot
        address[] memory path2 = new address[](2);
        path2[0] = USDC;
        path2[1] = WETH;
        
        IUniswapV2Router(CAMELOT).swapExactTokensForTokens(
            usdcBalance,
            amount, // Must get back at least what we borrowed
            path2,
            address(this),
            block.timestamp + 300
        );
        
        uint256 endBalance = IERC20(WETH).balanceOf(address(this));
        
        require(endBalance > startBalance, "No profit");
        profit = endBalance - startBalance;
        
        emit ArbitrageExecuted(WETH, USDC, amount, usdcBalance, profit);
        
        return profit;
    }
    
    /**
     * @notice Execute ARB arbitrage loop
     * @dev ARB → WETH → USDC → WETH → ARB
     */
    function _executeARBArbitrage(uint256 amount) internal returns (uint256 profit) {
        uint256 startBalance = IERC20(ARB).balanceOf(address(this));
        
        // Complex 4-hop arbitrage
        
        // 1. ARB → WETH
        address[] memory path1 = new address[](2);
        path1[0] = ARB;
        path1[1] = WETH;
        
        IUniswapV2Router(SUSHISWAP).swapExactTokensForTokens(
            amount,
            0,
            path1,
            address(this),
            block.timestamp + 300
        );
        
        uint256 wethBalance = IERC20(WETH).balanceOf(address(this));
        
        // 2. WETH → USDC
        address[] memory path2 = new address[](2);
        path2[0] = WETH;
        path2[1] = USDC;
        
        IUniswapV2Router(CAMELOT).swapExactTokensForTokens(
            wethBalance,
            0,
            path2,
            address(this),
            block.timestamp + 300
        );
        
        uint256 usdcBalance = IERC20(USDC).balanceOf(address(this));
        
        // 3. USDC → WETH
        address[] memory path3 = new address[](2);
        path3[0] = USDC;
        path3[1] = WETH;
        
        IUniswapV2Router(SUSHISWAP).swapExactTokensForTokens(
            usdcBalance,
            0,
            path3,
            address(this),
            block.timestamp + 300
        );
        
        wethBalance = IERC20(WETH).balanceOf(address(this));
        
        // 4. WETH → ARB
        address[] memory path4 = new address[](2);
        path4[0] = WETH;
        path4[1] = ARB;
        
        IUniswapV2Router(CAMELOT).swapExactTokensForTokens(
            wethBalance,
            amount, // Must get back at least what we borrowed
            path4,
            address(this),
            block.timestamp + 300
        );
        
        uint256 endBalance = IERC20(ARB).balanceOf(address(this));
        
        require(endBalance > startBalance, "No profit");
        profit = endBalance - startBalance;
        
        return profit;
    }
    
    // ============ ADMIN FUNCTIONS ============
    
    function setMinProfitBasisPoints(uint256 _bps) external onlyOwner {
        require(_bps <= 1000, "Max 10%");
        minProfitBasisPoints = _bps;
    }
    
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }
    
    function withdrawProfit(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "No balance");
        
        IERC20(token).transfer(owner(), balance);
        
        emit ProfitWithdrawn(token, balance, owner());
    }
    
    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH");
        payable(owner()).transfer(balance);
    }
    
    // ============ VIEW FUNCTIONS ============
    
    function getStats() external view returns (
        uint256 _totalFlashLoans,
        uint256 _totalProfit,
        uint256 _totalVolume,
        bool _paused
    ) {
        return (totalFlashLoans, totalProfit, totalVolume, paused);
    }
    
    function estimateProfit(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address router
    ) external view returns (uint256 estimatedOut) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        
        uint256[] memory amounts = IUniswapV2Router(router).getAmountsOut(
            amountIn,
            path
        );
        
        return amounts[1];
    }
    
    // Receive ETH
    receive() external payable {}
}

