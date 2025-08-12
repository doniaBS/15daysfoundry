// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {MockERC20} from "../src/MockERC20.sol";

contract Swap {
    function swap(MockERC20 tokenA, MockERC20 tokenB, uint256 amount) public {
        require(amount > 0, "amount = 0");

        // Take tokenA from user
        tokenA.transferFrom(msg.sender, address(this), amount);

        // Send tokenB from contract to user
        tokenB.transfer(msg.sender, amount);
    }
}