// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ERC20Mintable} from "../src/ERC20Mintable.sol";

contract ERC20MintableTest is Test {
    ERC20Mintable token;

    function setUp() public {
        token = new ERC20Mintable("MyToken", "MTK"); // pass name and symbol
    }

    function testMint() public {
        token.mint(address(this), 1000);
        assertEq(token.balanceOf(address(this)), 1000);
    }
}
