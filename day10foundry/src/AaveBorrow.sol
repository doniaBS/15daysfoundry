// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// interface to interact with Aave LendingPool
interface ILendingPool {
    function borrow(
        address asset, 
        uint256 amount, 
        uint256 interestRateMode, 
        uint16 referralCode, 
        address onBehalfOf
    ) external;
}

// Minterface to read ERC20 token balances
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract AaveBorrow {
    // Aave LendingPool contract address on mainnet
    ILendingPool public lendingPool;

    // USDC token contract address on mainnet
    IERC20 public usdc;

    // Constructor: set the addresses of LendingPool and USDC
    constructor(address _lendingPool, address _usdc) {
        lendingPool = ILendingPool(_lendingPool);
        usdc = IERC20(_usdc);
    }

    /**
     * Borrow USDC from Aave
     * @param amount Amount of USDC to borrow (6 decimals)
     */
    function borrowUSDC(uint256 amount) external {
        // interestRateMode = 2 → variable rate
        // referralCode = 0 → no referral
        // onBehalfOf = msg.sender → the caller receives the USDC
        lendingPool.borrow(address(usdc), amount, 2, 0, msg.sender);
    }

    /**
     * Check USDC balance of any address
     * @param user Address to check
     * @return balance USDC balance of the user
     */
    function getUSDCBalance(address user) external view returns (uint256) {
        return usdc.balanceOf(user);
    }
}
