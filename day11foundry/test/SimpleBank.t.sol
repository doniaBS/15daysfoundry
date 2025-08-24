// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SimpleBank} from "../src/SimpleBank.sol";

contract SimpleBankTest is Test {
    SimpleBank bank;

    function setUp() public {
        bank = new SimpleBank();
    }

    function testDeposit() public {
        // Deposit 1 ether
        bank.deposit{value: 1 ether}();
        // Check balance is 1 ether
        assertEq(bank.getBalance(), 1 ether);
    }

    function testWithdraw() public {
        vm.deal(address(this), 10 ether);

        bank.deposit{value: 2 ether}();
         vm.expectRevert();
        bank.withdraw(1 ether);
    }


    function testWithdrawInsufficientBalance() public {
        bank.deposit{value: 1 ether}();
        // Expect revert because trying to withdraw more than deposited
        vm.expectRevert();
        bank.withdraw(2 ether);
        
    }

    function testDepositZeroReverts() public {
        // Expect revert because deposit of zero is not allowed
        vm.expectRevert("Must deposit more than 0");
        bank.deposit{value: 0}();
    }
}
