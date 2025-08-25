// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";

contract VaultTest is Test {
    Vault vault;
    address owner = address(0xA11CE);
    address user = address(0xB0B);
    address attackerEOA = address(0xA77A);

    function setUp() public {
        vault = new Vault(owner);
        // Seed users with ETH
        vm.deal(user, 100 ether);
        vm.deal(attackerEOA, 100 ether);
        vm.deal(owner, 100 ether);
    }

    /*//////////////////////////////////////////////////////////////
                          BASIC DEPOSIT / WITHDRAW
    //////////////////////////////////////////////////////////////*/
    function test_DepositIncreasesBalance() public {
        vm.prank(user);
        vault.deposit{value: 5 ether}();
        assertEq(vault.balanceOf(user), 5 ether);
    }

    function test_ReceiveCountsAsDeposit() public {
        vm.prank(user);
        (bool ok, ) = address(vault).call{value: 1 ether}("");
        assertTrue(ok);
        assertEq(vault.balanceOf(user), 1 ether);
    }

    function test_WithdrawHappyPath() public {
        vm.prank(user);
        vault.deposit{value: 7 ether}();

        uint256 before = user.balance;

        vm.prank(user);
        vault.withdraw(3 ether);

        assertEq(vault.balanceOf(user), 4 ether);
        assertEq(user.balance, before + 3 ether);
    }

    function test_RevertOnZeroAmountDeposit() public {
        vm.prank(user);
        vm.expectRevert(bytes("ZeroAmount"));
        vault.deposit{value: 0}();
    }

    function test_RevertOnZeroAmountWithdraw() public {
        vm.prank(user);
        vm.expectRevert(bytes("ZeroAmount"));
        vault.withdraw(0);
    }

    function test_RevertOnInsufficientBalance() public {
        vm.prank(user);
        vm.expectRevert(bytes("Insufficient"));
        vault.withdraw(1 ether);
    }

    /*//////////////////////////////////////////////////////////////
                              ACCESS CONTROL
    //////////////////////////////////////////////////////////////*/
    function test_OnlyOwnerCanPause() public {
        // Non-owner tries
        vm.prank(user);
        vm.expectRevert(bytes("NotOwner"));
        vault.pause();

        // Owner pauses
        vm.prank(owner);
        vault.pause();
        assertTrue(vault.paused());

        // Non-owner tries to unpause
        vm.prank(user);
        vm.expectRevert(bytes("NotOwner"));
        vault.unpause();

        // Owner unpauses
        vm.prank(owner);
        vault.unpause();
        assertFalse(vault.paused());
    }

    function test_TransferOwnership() public {
        vm.prank(owner);
        vault.transferOwnership(user);
        assertEq(vault.owner(), user);

        // Old owner can no longer pause
        vm.prank(owner);
        vm.expectRevert(bytes("NotOwner"));
        vault.pause();

        // New owner can pause
        vm.prank(user);
        vault.pause();
        assertTrue(vault.paused());
    }

    /*//////////////////////////////////////////////////////////////
                                 PAUSE
    //////////////////////////////////////////////////////////////*/
    function test_DepositBlockedWhenPaused() public {
        vm.prank(owner);
        vault.pause();

        vm.prank(user);
        vm.expectRevert(bytes("Paused"));
        vault.deposit{value: 1 ether}();
    }

    function test_WithdrawBlockedWhenPaused() public {
        vm.prank(user);
        vault.deposit{value: 2 ether}();

        vm.prank(owner);
        vault.pause();

        vm.prank(user);
        vm.expectRevert(bytes("Paused"));
        vault.withdraw(1 ether);
    }

    function test_ReceiveBlockedWhenPaused() public {
        vm.prank(owner);
        vault.pause();

        vm.prank(user);
        (bool ok, ) = address(vault).call{value: 1 ether}("");
        assertFalse(ok); // Paused receive reverts
    }

    /*//////////////////////////////////////////////////////////////
                             REENTRANCY TEST
    //////////////////////////////////////////////////////////////*/
    function test_ReentrancyAttemptFails() public {
        // User deposits so the attacker can target that balance later
        vm.prank(user);
        vault.deposit{value: 10 ether}();

        // Deploy attacker that tries to reenter during withdraw
        Attacker attacker = new Attacker(vault);
        vm.deal(address(attacker), 1 ether);

        // Move funds to attacker to have a balance to withdraw
        // (attacker deposits)
        vm.prank(address(attacker));
        vault.deposit{value: 1 ether}();

        // The attacker attempts to reenter via fallback -> withdraw again.
        // Our nonReentrant guard should block and revert with "Reentrancy".
        vm.expectRevert(bytes("Reentrancy"));
        attacker.attack(1 ether);
    }
}

/*//////////////////////////////////////////////////////////////
                     MALICIOUS REENTRANCY ATTACKER
//////////////////////////////////////////////////////////////*/
contract Attacker {
    Vault public vault;
    bool internal reentered;

    constructor(Vault _vault) {
        vault = _vault;
    }

    // Start reentrancy by calling withdraw
    function attack(uint256 amount) external {
        // Withdraw once; fallback will try to withdraw again
        vault.withdraw(amount);
    }

    // When receiving ETH from the vault, try to reenter
    receive() external payable {
        if (!reentered) {
            reentered = true;
            // Try to reenter
            vault.withdraw(1); // any positive amount would do
        }
    }
}
