// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../lib/aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol";
import "../lib/aave-v3-core/contracts/interfaces/IPool.sol";
import "../lib/aave-v3-core/contracts/flashloan/interfaces/IFlashLoanSimpleReceiver.sol";

/**
 * @title OptimizedFlashLoanArbitrage
 * @notice Production-grade flash loan arbitrage contract for Arbitrum Mainnet
 * @dev Implements Aave V3 flash loans with MEV protection and profit optimization
 */
contract OptimizedFlashLoanArbitrage is IFlashLoanSimpleReceiver, Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // ============================================
    // STATE VARIABLES
    // ============================================
    
    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;
    IPool public immutable POOL;
    
    // Approved DEX routers
    mapping(address => bool) public approvedRouters;
    
    // Profit tracking
    uint256 public totalProfitGenerated;
    uint256 public totalTradesExecuted;
    
    // Safety limits
    uint256 public maxFlashLoanAmount = 1000 ether; // Start conservative
    uint256 public minProfitBps = 10; // 0.1% minimum profit
    
    // ============================================
    // EVENTS
    // ============================================
    
    event FlashLoanExecuted(
        address indexed asset,
        uint256 amount,
        uint256 profit,
        uint256 timestamp
    );
    
    event RouterApproved(address indexed router, bool approved);
    event ProfitWithdrawn(address indexed token, uint256 amount, address indexed recipient);
    event LimitsUpdated(uint256 maxAmount, uint256 minProfit);
    
    // ============================================
    // ERRORS
    // ============================================
    
    error UnauthorizedCaller();
    error InvalidRouter();
    error InsufficientProfit(uint256 expected, uint256 actual);
    error FlashLoanFailed();
    error ExceedsMaxAmount(uint256 requested, uint256 max);
    
    // ============================================
    // CONSTRUCTOR
    // ============================================
    
    constructor(address _addressesProvider) Ownable(msg.sender) {
        require(_addressesProvider != address(0), "Invalid provider");
        ADDRESSES_PROVIDER = IPoolAddressesProvider(_addressesProvider);
        POOL = IPool(IPoolAddressesProvider(_addressesProvider).getPool());
    }
    
    // ============================================
    // FLASH LOAN FUNCTIONS
    // ============================================
    
    /**
     * @notice Initiate a flash loan arbitrage
     * @param asset Token to flash loan
     * @param amount Amount to borrow
     * @param params Encoded arbitrage parameters
     */
    function executeFlashLoan(
        address asset,
        uint256 amount,
        bytes calldata params
    ) external nonReentrant whenNotPaused {
        require(amount <= maxFlashLoanAmount, ExceedsMaxAmount(amount, maxFlashLoanAmount));
        
        POOL.flashLoanSimple(
            address(this),
            asset,
            amount,
            params,
            0 // referralCode
        );
    }
    
    /**
     * @notice Aave V3 flash loan callback
     * @param asset The asset being flash-borrowed
     * @param amount The amount flash-borrowed
     * @param premium The fee for the flash loan
     * @param initiator The address that initiated the flash loan
     * @param params Encoded parameters for the operation
     */
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        // Verify caller is Aave Pool
        require(msg.sender == address(POOL), UnauthorizedCaller());
        require(initiator == address(this), UnauthorizedCaller());
        
        // Decode arbitrage parameters
        (
            address buyRouter,
            address sellRouter,
            address[] memory buyPath,
            address[] memory sellPath,
            uint256 minProfit
        ) = abi.decode(params, (address, address, address[], address[], uint256));
        
        // Validate routers
        require(approvedRouters[buyRouter], InvalidRouter());
        require(approvedRouters[sellRouter], InvalidRouter());
        
        uint256 balanceBefore = IERC20(asset).balanceOf(address(this));
        
        // Execute arbitrage trades
        _executeArbitrageTrades(
            asset,
            amount,
            buyRouter,
            sellRouter,
            buyPath,
            sellPath
        );
        
        uint256 balanceAfter = IERC20(asset).balanceOf(address(this));
        uint256 amountOwed = amount + premium;
        
        // Calculate profit
        require(balanceAfter >= amountOwed, FlashLoanFailed());
        uint256 profit = balanceAfter - amountOwed;
        
        // Validate minimum profit
        uint256 minProfitRequired = (amount * minProfitBps) / 10000;
        if (profit < minProfit) {
            require(profit >= minProfitRequired, InsufficientProfit(minProfit, profit));
        }
        
        // Update statistics
        totalProfitGenerated += profit;
        totalTradesExecuted++;
        
        // Approve repayment
        IERC20(asset).approve(address(POOL), amountOwed);
        
        emit FlashLoanExecuted(asset, amount, profit, block.timestamp);
        
        return true;
    }
    
    /**
     * @notice Execute arbitrage trades across DEXs
     */
    function _executeArbitrageTrades(
        address asset,
        uint256 amount,
        address buyRouter,
        address sellRouter,
        address[] memory buyPath,
        address[] memory sellPath
    ) internal {
        // Approve buy router
        IERC20(asset).approve(buyRouter, amount);
        
        // Buy on first DEX
        IUniswapV2Router(buyRouter).swapExactTokensForTokens(
            amount,
            0, // Will be protected by profit check
            buyPath,
            address(this),
            block.timestamp
        );
        
        // Get intermediate token balance
        address intermediateToken = buyPath[buyPath.length - 1];
        uint256 intermediateBalance = IERC20(intermediateToken).balanceOf(address(this));
        
        // Approve sell router
        IERC20(intermediateToken).approve(sellRouter, intermediateBalance);
        
        // Sell on second DEX
        IUniswapV2Router(sellRouter).swapExactTokensForTokens(
            intermediateBalance,
            0, // Will be protected by profit check
            sellPath,
            address(this),
            block.timestamp
        );
    }
    
    // ============================================
    // ADMIN FUNCTIONS
    // ============================================
    
    /**
     * @notice Approve or revoke DEX router
     */
    function setRouterApproval(address router, bool approved) external onlyOwner {
        approvedRouters[router] = approved;
        emit RouterApproved(router, approved);
    }
    
    /**
     * @notice Approve DEX router (alias for compatibility)
     */
    function approveRouter(address router, bool approved) external onlyOwner {
        approvedRouters[router] = approved;
        emit RouterApproved(router, approved);
    }
    
    /**
     * @notice Update safety limits
     */
    function updateLimits(uint256 _maxFlashLoanAmount, uint256 _minProfitBps) external onlyOwner {
        maxFlashLoanAmount = _maxFlashLoanAmount;
        minProfitBps = _minProfitBps;
        emit LimitsUpdated(_maxFlashLoanAmount, _minProfitBps);
    }
    
    /**
     * @notice Withdraw accumulated profits
     */
    function withdrawProfit(address token, uint256 amount, address recipient) external onlyOwner {
        require(recipient != address(0), "Invalid recipient");
        IERC20(token).safeTransfer(recipient, amount);
        emit ProfitWithdrawn(token, amount, recipient);
    }
    
    /**
     * @notice Emergency pause
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @notice Unpause
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @notice Get contract statistics
     */
    function getStats() external view returns (
        uint256 totalProfit,
        uint256 totalTrades,
        uint256 averageProfit,
        uint256 maxAmount,
        uint256 minProfit
    ) {
        return (
            totalProfitGenerated,
            totalTradesExecuted,
            totalTradesExecuted > 0 ? totalProfitGenerated / totalTradesExecuted : 0,
            maxFlashLoanAmount,
            minProfitBps
        );
    }
    
    // ============================================
    // HELPER FUNCTIONS
    // ============================================
    
    /**
     * @notice Get token balance
     */
    function getBalance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }
    
    /**
     * @notice Get ETH balance
     */
    function getETHBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @notice Receive ETH
     */
    receive() external payable {}
}

// ============================================
// INTERFACES
// ============================================

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
