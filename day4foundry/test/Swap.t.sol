// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TokenSwap.sol";

contract SwapTest is Test {
    Swap swap;
    MockERC20 tokenA;
    MockERC20 tokenB;
    address user = address(0x123);

    function setUp() public {
        swap = new Swap();
        tokenA = new MockERC20("TokenA");
        tokenB = new MockERC20("TokenB");

        // Give user tokenA and contract tokenB for swaps
        tokenA.mint(user, 1_000_000);
        tokenB.mint(address(swap), 1_000_000);
    }

    function testFuzzSwap(uint256 amount) public {
        // Bound the amount between 1 and user's balance
        amount = bound(amount, 1, tokenA.balanceOf(user));

        // Approve and swap
        vm.startPrank(user);
        tokenA.approve(address(swap), amount);
        swap.swap(tokenA, tokenB, amount);
        vm.stopPrank();

        // Assert balances changed 1:1
        assertEq(tokenA.balanceOf(user), 1_000_000 - amount);
        assertEq(tokenB.balanceOf(user), amount);
    }
}