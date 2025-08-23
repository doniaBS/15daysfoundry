// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SimpleBank.sol";

contract SimpleBankTest is Test {
    SimpleBank bank;
    address user = address(0x123);

    function setUp() public {
        bank = new SimpleBank();
        vm.deal(user, 1 ether); // give user some ETH
    }

    function testDeposit() public {
        vm.prank(user);
        bank.deposit{value: 0.5 ether}();
        assertEq(bank.getBalance(), 0.5 ether);
    }

    function testWithdraw() public {
        vm.startPrank(user);
        bank.deposit{value: 0.5 ether}();
        bank.withdraw(0.2 ether);
        vm.stopPrank();
        assertEq(bank.getBalance(), 0.3 ether);
    }
}
