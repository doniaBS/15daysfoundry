// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {MonthlySubscription} from "../src/Subscription.sol";

contract SubscriptionTest is Test {
    MonthlySubscription public subscription;
    address public owner = address(0x1);
    address public subscriber1 = address(0x2);
    address public subscriber2 = address(0x3);
    
    uint256 public constant MONTHLY_RATE = 1 ether;

    function setUp() public {
        vm.prank(owner);
        subscription = new MonthlySubscription();
    }

    function testSubscribe() public {
        vm.prank(subscriber1);
        subscription.subscribe{value: MONTHLY_RATE}(MONTHLY_RATE);
        
        (address subAddr,,,uint256 rate,bool isActive) = subscription.getSubscription(subscriber1);
        assertEq(subAddr, subscriber1);
        assertEq(rate, MONTHLY_RATE);
        assertTrue(isActive);
        assertTrue(subscription.isSubscriber(subscriber1));
    }

    function testSubscribeAlreadySubscribed() public {
        vm.prank(subscriber1);
        subscription.subscribe{value: MONTHLY_RATE}(MONTHLY_RATE);
        
        vm.expectRevert("Already subscribed");
        vm.prank(subscriber1);
        subscription.subscribe{value: MONTHLY_RATE}(MONTHLY_RATE);
    }

    function testMakePayment() public {
        vm.prank(subscriber1);
        subscription.subscribe{value: MONTHLY_RATE}(MONTHLY_RATE);
        
        // Fast forward 30 days
        vm.warp(block.timestamp + 30 days);
        
        vm.prank(subscriber1);
        subscription.makePayment{value: MONTHLY_RATE}();
        
        (, , uint256 lastPaymentTime, , ) = subscription.getSubscription(subscriber1);
        assertEq(lastPaymentTime, block.timestamp);
    }

    function testMakePaymentTooEarly() public {
        vm.prank(subscriber1);
        subscription.subscribe{value: MONTHLY_RATE}(MONTHLY_RATE);
        
        // Try to pay again immediately
        vm.expectRevert("Too early for next payment");
        vm.prank(subscriber1);
        subscription.makePayment{value: MONTHLY_RATE}();
    }

    function testCancelSubscription() public {
        vm.prank(subscriber1);
        subscription.subscribe{value: MONTHLY_RATE}(MONTHLY_RATE);
        
        vm.prank(subscriber1);
        subscription.cancelSubscription();
        
        (, , , , bool isActive) = subscription.getSubscription(subscriber1);
        assertFalse(isActive);
        assertFalse(subscription.isSubscriber(subscriber1));
    }

    function testIsSubscriptionActive() public {
        vm.prank(subscriber1);
        subscription.subscribe{value: MONTHLY_RATE}(MONTHLY_RATE);
        
        assertTrue(subscription.isSubscriptionActive(subscriber1));
        
        // After 40 days without payment (grace period is 35 days)
        vm.warp(block.timestamp + 40 days);
        assertFalse(subscription.isSubscriptionActive(subscriber1));
    }

    function testWithdrawFunds() public {
        vm.prank(subscriber1);
        subscription.subscribe{value: MONTHLY_RATE}(MONTHLY_RATE);
        
        vm.prank(subscriber2);
        subscription.subscribe{value: MONTHLY_RATE}(MONTHLY_RATE);
        
        uint256 initialBalance = owner.balance;
        uint256 contractBalance = address(subscription).balance;
        
        vm.prank(owner);
        subscription.withdrawFunds();
        
        assertEq(owner.balance, initialBalance + contractBalance);
        assertEq(address(subscription).balance, 0);
    }

    function testEmergencyCancel() public {
        vm.prank(subscriber1);
        subscription.subscribe{value: MONTHLY_RATE}(MONTHLY_RATE);
        
        vm.prank(owner);
        subscription.emergencyCancel(subscriber1);
        
        (, , , , bool isActive) = subscription.getSubscription(subscriber1);
        assertFalse(isActive);
    }

    function testOnlyOwnerWithdraw() public {
        vm.prank(subscriber1);
        subscription.subscribe{value: MONTHLY_RATE}(MONTHLY_RATE);
        
        vm.expectRevert("Only owner can call this function");
        vm.prank(subscriber1);
        subscription.withdrawFunds();
    }

    function testOnlySubscriberMakePayment() public {
        vm.expectRevert("Only subscribers can call this function");
        vm.prank(subscriber1);
        subscription.makePayment{value: MONTHLY_RATE}();
    }
}
