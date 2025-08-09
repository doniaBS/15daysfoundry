// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

contract CounterTest is Test {
    Counter counter;

    function setUp() public {
        counter = new Counter();
    }

    function testInitialNumberIsZero() public {
        assertEq(counter.number(), 0);
    }

    function testSetNumber() public {
        counter.setNumber(10);
        assertEq(counter.number(), 10);
    }

    function testIncrement() public {
        counter.setNumber(5);
        counter.increment();
        assertEq(counter.number(), 6);
    }

    function testDecrement() public {
        counter.setNumber(5);
        counter.decrement();
        assertEq(counter.number(), 4);
    }

    function testDecrementUnderflowReverts() public {
        counter.setNumber(0);
        vm.expectRevert();
        counter.decrement();
    }
}
