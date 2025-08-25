// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Crowdfund} from "../src/Crowdfund.sol";

contract CrowdfundTest is Test {
    Crowdfund public crowdfund;
    address public owner = address(0x1);
    address public creator = address(0x2);
    address public contributor1 = address(0x3);
    address public contributor2 = address(0x4);
    address public feeRecipient = address(0x5);

    uint256 constant TARGET = 10 ether;
    uint256 constant DEADLINE = 30 days;
    uint256 constant PLATFORM_FEE = 200; // 2%

    function setUp() public {
        vm.prank(owner);
        crowdfund = new Crowdfund(PLATFORM_FEE, feeRecipient);
    }

    // Day 3: Testing Basics
    function test_CreateCampaign() public {
        vm.prank(creator);
        uint256 campaignId = crowdfund.createCampaign(
            "Test Campaign",
            "Test Description",
            TARGET,
            block.timestamp + DEADLINE,
            "QmImageHash"
        );

        assertEq(campaignId, 1);
        assertEq(crowdfund.campaignCount(), 1);

        Crowdfund.Campaign memory campaign = crowdfund.getCampaign(campaignId);
        assertEq(campaign.title, "Test Campaign");
        assertEq(campaign.target, TARGET);
        assertEq(campaign.creator, creator);
    }

    function test_RevertWhen_CreateCampaignWithInvalidTarget() public {
        vm.prank(creator);
        vm.expectRevert(Crowdfund.InvalidTarget.selector);
        crowdfund.createCampaign(
            "Test Campaign",
            "Test Description",
            0,
            block.timestamp + DEADLINE,
            "QmImageHash"
        );
    }

    // Day 4: Fuzzing and Property Testing
    function testFuzz_ContributeToCampaign(uint96 amount) public {
        vm.assume(amount > 0.1 ether && amount < 100 ether);
        
        vm.prank(creator);
        uint256 campaignId = crowdfund.createCampaign(
            "Fuzz Campaign",
            "Fuzz Description",
            TARGET,
            block.timestamp + DEADLINE,
            "QmImageHash"
        );

        vm.deal(contributor1, amount);
        vm.prank(contributor1);
        crowdfund.contribute{value: amount}(campaignId);

        assertEq(crowdfund.userContributions(campaignId, contributor1), amount);
    }

    // Day 5: Gas Optimization & Reports
    function test_Gas_ContributeToCampaign() public {
        vm.prank(creator);
        uint256 campaignId = crowdfund.createCampaign(
            "Gas Test Campaign",
            "Testing gas costs",
            TARGET,
            block.timestamp + DEADLINE,
            "QmImageHash"
        );

        vm.deal(contributor1, 5 ether);
        vm.prank(contributor1);
        crowdfund.contribute{value: 5 ether}(campaignId);
    }

    // Day 6: Time Travel & Events
    function test_WithdrawFundsSuccess() public {
        vm.prank(creator);
        uint256 campaignId = crowdfund.createCampaign(
            "Test Campaign",
            "Test Description",
            TARGET,
            block.timestamp + DEADLINE,
            "QmImageHash"
        );

        vm.deal(contributor1, 10 ether);
        vm.prank(contributor1);
        crowdfund.contribute{value: 10 ether}(campaignId);

        // Time travel to after deadline
        vm.warp(block.timestamp + DEADLINE + 1);
        
        // Check that the campaign creator can withdraw
        vm.prank(creator);
        crowdfund.withdrawFunds(campaignId);

        assertEq(address(creator).balance, 9.8 ether); // After 2% fee
        assertEq(address(feeRecipient).balance, 0.2 ether);
    }

    function test_RefundWhenTargetNotReached() public {
        vm.prank(creator);
        uint256 campaignId = crowdfund.createCampaign(
            "Test Campaign",
            "Test Description",
            TARGET,
            block.timestamp + DEADLINE,
            "QmImageHash"
        );

        vm.deal(contributor1, 5 ether);
        vm.prank(contributor1);
        crowdfund.contribute{value: 5 ether}(campaignId);

        // Time travel to after deadline
        vm.warp(block.timestamp + DEADLINE + 1);
        
        uint256 balanceBefore = contributor1.balance;
        vm.prank(contributor1);
        crowdfund.refund(campaignId);

        assertEq(contributor1.balance, balanceBefore + 5 ether);
    }

    // Day 13: Security & Testing Cheatcodes
    function test_RevertWhen_NonCreatorTriesToWithdraw() public {
        vm.prank(creator);
        uint256 campaignId = crowdfund.createCampaign(
            "Test Campaign",
            "Test Description",
            TARGET,
            block.timestamp + DEADLINE,
            "QmImageHash"
        );

        vm.deal(contributor1, 10 ether);
        vm.prank(contributor1);
        crowdfund.contribute{value: 10 ether}(campaignId);

        vm.warp(block.timestamp + DEADLINE + 1);
        
        // Impersonate a different address
        vm.prank(contributor2);
        vm.expectRevert(Crowdfund.NotCampaignCreator.selector);
        crowdfund.withdrawFunds(campaignId);
    }

    function test_Invariant_CampaignBalance() public {
        vm.prank(creator);
        uint256 campaignId = crowdfund.createCampaign(
            "Invariant Campaign",
            "Testing invariants",
            TARGET,
            block.timestamp + DEADLINE,
            "QmImageHash"
        );

        vm.deal(contributor1, 3 ether);
        vm.deal(contributor2, 4 ether);
        
        vm.prank(contributor1);
        crowdfund.contribute{value: 3 ether}(campaignId);
        
        vm.prank(contributor2);
        crowdfund.contribute{value: 4 ether}(campaignId);

        Crowdfund.Campaign memory campaign = crowdfund.getCampaign(campaignId);
        assertEq(campaign.amountCollected, 7 ether);
        assertEq(campaign.totalContributors, 2);
    }

    // Test view functions
    function test_GetActiveCampaigns() public {
        vm.prank(creator);
        uint256 campaignId = crowdfund.createCampaign(
            "Active Campaign",
            "Should be active",
            TARGET,
            block.timestamp + DEADLINE,
            "QmImageHash"
        );

        Crowdfund.Campaign[] memory activeCampaigns = crowdfund.getActiveCampaigns();
        assertEq(activeCampaigns.length, 1);
        assertEq(activeCampaigns[0].id, campaignId);
    }

    function test_GetUserCampaigns() public {
        vm.prank(creator);
        uint256 campaignId = crowdfund.createCampaign(
            "User Campaign",
            "User's campaign",
            TARGET,
            block.timestamp + DEADLINE,
            "QmImageHash"
        );

        uint256[] memory userCampaigns = crowdfund.getUserCampaigns(creator);
        assertEq(userCampaigns.length, 1);
        assertEq(userCampaigns[0], campaignId);
    }

    // Test platform fee update
    function test_PlatformFeeUpdate() public {
        uint256 newFee = 300; // 3%
        vm.prank(owner);
        crowdfund.setPlatformFee(newFee);
        
        assertEq(crowdfund.platformFee(), newFee);
    }

    // Test fee recipient update
    function test_FeeRecipientUpdate() public {
        address newRecipient = address(0x6);
        vm.prank(owner);
        crowdfund.setFeeRecipient(newRecipient);
        
        assertEq(crowdfund.feeRecipient(), newRecipient);
    }

    // Test unauthorized access - Use OpenZeppelin's error message
    function test_RevertWhen_NonOwnerUpdatesFee() public {
        vm.prank(contributor1);
        vm.expectRevert("Ownable: caller is not the owner");
        crowdfund.setPlatformFee(100);
    }

    // Test invalid fee
    function test_RevertWhen_InvalidFee() public {
        vm.prank(owner);
        vm.expectRevert(Crowdfund.InvalidFee.selector);
        crowdfund.setPlatformFee(1001); // More than 10%
    }

    // Test campaign not found
    function test_RevertWhen_CampaignNotFound() public {
        vm.expectRevert(Crowdfund.CampaignNotFound.selector);
        crowdfund.getCampaign(999); // Non-existent campaign
    }
}