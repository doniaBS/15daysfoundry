// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MonthlySubscription} from "../src/Subscription.sol";

contract DeploySubscription is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        MonthlySubscription subscription = new MonthlySubscription();
        
        console.log("Subscription contract deployed at:", address(subscription));
        console.log("Owner:", address(msg.sender));
        
        vm.stopBroadcast();
    }
}