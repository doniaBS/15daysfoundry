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
        // first declare owners as a new array in memory
        address;
        owners[0] = a;
        owners[1] = b;
        owners[2] = c;

        // now pass it into the Wallet constructor
        w = new Wallet(owners, 2);

        // give some ETH to test accounts + wallet
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

    // Fuzz: any two distinct owners can execute
    function testFuzz_TwoDistinctOwnersExecute(address o1, address o2) public {
        // constrain to actual owners
        vm.assume(o1 == a || o1 == b || o1 == c);
        vm.assume(o2 == a || o2 == b || o2 == c);
        vm.assume(o1 != o2);

        vm.prank(a);
        uint txId = w.submit(address(0xBEEF), 2 ether, "");

        vm.prank(o1);
        w.confirm(txId);
        vm.prank(o2);
        w.confirm(txId);

        assertTrue(w.getTx(txId).executed);
        assertEq(address(0xBEEF).balance, 2 ether);
    }
}
