// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Voting} from "../src/Voting.sol";

contract VotingTest is Test {
     Voting voting;

    address owner = address(0xABCD);
    address voter1 = address(0x1234);

    function setUp() public {
        voting = new Voting(owner);
    }

    function testOwnerCanAddProposal() public {
        vm.prank(owner);
        voting.addProposal("Proposal 1");
        (string memory desc, ) = voting.getProposal(0);
        assertEq(desc, "Proposal 1");
    }

    function testNonOwnerCannotAddProposal() public {
        vm.expectRevert(); // should revert
        voting.addProposal("Proposal 2");
    }

    function testVote() public {
        vm.prank(owner);
        voting.addProposal("Proposal 3");

        vm.prank(voter1);
        voting.vote(0);

        (, uint256 votes) = voting.getProposal(0);
        assertEq(votes, 1);
    }
}
