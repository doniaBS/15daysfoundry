// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Voting} from "../src/Voting.sol";

contract VotingScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy and set msg.sender (owner)
        Voting voting = new Voting(msg.sender);

        vm.stopBroadcast();

        console.log("Voting contract deployed at:", address(voting));
    }
}
