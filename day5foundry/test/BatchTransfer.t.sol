// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {BatchTransfer} from "../src/BatchTransfer.sol";

contract BatchTransferTest is Test {
    BatchTransfer public batchTransfer;

    function setUp() public {
        batchTransfer = new BatchTransfer();
        batchTransfer.setNumber(0);
    }
}
