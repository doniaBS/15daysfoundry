// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Wallet} from "../src/Wallet.sol";

contract WalletTest is Test {
    Wallet w;
    address a = address(0xA11CE);
    address b = address(0xB0B);
    address c = address(0xC0DE);

    function setUp() public {
        // Declare the owners array first
        address[] memory owners = new address[](3);
        owners[0] = a;
        owners[1] = b;
        owners[2] = c;

        // pass it into the Wallet constructor
        w = new Wallet(owners, 2);

        // fund accounts
        vm.deal(a, 100 ether);
        vm.deal(b, 100 ether);
        vm.deal(c, 100 ether);
        vm.deal(address(this), 100 ether);

        // deposit into the wallet
        (bool ok, ) = address(w).call{value: 50 ether}("");
        assertTrue(ok);
    }

    function testSubmitConfirmExecuteTransfer() public {
        // submit by owner A
        vm.prank(a);
        uint txId = w.submit(address(0xdead), 1 ether, "");

        // confirm by A and B (auto-exec on 2nd confirm)
        vm.prank(a);
        w.confirm(txId);
        vm.prank(b);
        w.confirm(txId);

        assertTrue(w.getTx(txId).executed);
        assertEq(address(0xdead).balance, 1 ether);
    }

    function testRevokeBeforeExecute() public {
        vm.startPrank(a);
        uint txId = w.submit(address(123), 1 ether, "");
        w.confirm(txId);
        vm.stopPrank();

        vm.prank(a);
        w.revoke(txId);
        assertEq(w.getTx(txId).confirmations, 0);
    }

    // Test specific owner combinations instead of fuzzing addresses
    function testTwoDistinctOwnersExecute() public {
        // Test all possible combinations of two distinct owners
        address[] memory walletOwners = w.getOwners();

        // Test a+b
        testOwnerCombination(walletOwners[0], walletOwners[1]);

        // Test a+c
        testOwnerCombination(walletOwners[0], walletOwners[2]);

        // Test b+c
        testOwnerCombination(walletOwners[1], walletOwners[2]);
    }

    function testOwnerCombination(address o1, address o2) private {
        vm.prank(a);
        uint txId = w.submit(address(0xBEEF), 2 ether, "");

        vm.prank(o1);
        w.confirm(txId);
        vm.prank(o2);
        w.confirm(txId);

        assertTrue(w.getTx(txId).executed);
        assertEq(address(0xBEEF).balance, 2 ether);

        // Reset balance for next test
        vm.deal(address(0xBEEF), 0);
    }
}
