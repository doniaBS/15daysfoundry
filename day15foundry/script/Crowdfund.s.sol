// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Crowdfund} from "../src/Crowdfund.sol";

contract DeployCrowdfund is Script {
    function run() external returns (Crowdfund) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address feeRecipient = vm.envAddress("FEE_RECIPIENT");
        uint256 platformFee = vm.envUint("PLATFORM_FEE");
        
        vm.startBroadcast(deployerPrivateKey);

        Crowdfund crowdfund = new Crowdfund(platformFee, feeRecipient);
        
        vm.stopBroadcast();
        return crowdfund;
    }
}

contract DeployAndCreateCampaign is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address feeRecipient = vm.envAddress("FEE_RECIPIENT");
        uint256 platformFee = vm.envUint("PLATFORM_FEE");
        
        vm.startBroadcast(deployerPrivateKey);

        Crowdfund crowdfund = new Crowdfund(platformFee, feeRecipient);

        // Create a sample campaign
        crowdfund.createCampaign(
            "Foundry Bootcamp Campaign",
            "Capstone project campaign for Foundry Bootcamp",
            10 ether,
            block.timestamp + 30 days,
            "QmSampleImageHash"
        );
        
        vm.stopBroadcast();
    }
}