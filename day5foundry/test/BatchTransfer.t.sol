// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {BatchTransfer} from "../src/BatchTransfer.sol";
import {BatchTransferOp} from "../src/BatchTransferOp.sol";

contract BatchTransferTest is Test {
    BatchTransfer naive;
    BatchTransferOp optimized;

    address[] recipients;

    function setUp() public {
        naive = new BatchTransferNaive();
        optimized = new BatchTransferOptimized();

        // Example recipients
        recipients.push(address(0x1));
        recipients.push(address(0x2));
        recipients.push(address(0x3));

        function testNaiveBatchTransfer() public {
        naive.sendETH{value: 3 ether}(recipients, 1 ether);
    }

    function testOptimizedBatchTransfer() public {
        optimized.sendETH{value: 3 ether}(recipients, 1 ether);
    }
    }
}
