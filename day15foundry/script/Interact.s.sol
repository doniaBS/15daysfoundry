// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Crowdfund} from "../src/Crowdfund.sol";

contract InteractWithCrowdfund is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address crowdfundAddress = vm.envAddress("CROWDFUND_ADDRESS");
        
        vm.startBroadcast(privateKey);

        Crowdfund crowdfund = Crowdfund(crowdfundAddress);

        // Example: Create a campaign
        crowdfund.createCampaign(
            "Cast Example Campaign",
            "Created via cast script",
            5 ether,
            block.timestamp + 14 days,
            "QmCastExampleHash"
        );
        
        vm.stopBroadcast();
    }
}

contract ContributeToCampaign is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address crowdfundAddress = vm.envAddress("CROWDFUND_ADDRESS");
        
        vm.startBroadcast(privateKey);

        Crowdfund crowdfund = Crowdfund(crowdfundAddress);
        
        // Contribute to campaign ID 1
        crowdfund.contribute{value: 1 ether}(1);
        
        vm.stopBroadcast();
    }
}