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
        naive = new BatchTransfer();
        optimized = new BatchTransferOp();

        // Fund the sender account with enough ETH
        vm.deal(address(this), 10 ether);

        // Example recipients
        recipients.push(vm.addr(1));
        recipients.push(vm.addr(2));
        recipients.push(vm.addr(3));
        


    }

        function testNaiveBatchTransfer() public {
        naive.TransferEth{value: 3 ether}(recipients, 1 ether);
    }

    function testOptimizedBatchTransfer() public {
        optimized.SendEthOp{value: 3 ether}(recipients, 1 ether);
    }
}

