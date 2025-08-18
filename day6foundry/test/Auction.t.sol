// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Auction} from "../src/Auction.sol";

contract AuctionTest is Test {
    Auction auction;

    // Use safe, high-value addresses (not precompiles like 0x1, 0x2)
    address alice = address(0xABCD);
    address bob   = address(0xBEEF);

    // Redeclare events for expectEmit
    event BidPlaced(address indexed bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    // Allow test contract to receive ETH (for seller payout)
    receive() external payable {}

    function setUp() public {
        auction = new Auction(3 days); // Auction duration 3 days
    }

    function testBidAndRefund() public {
        // Alice places a bid
        vm.deal(alice, 1 ether);
        vm.prank(alice);

        vm.expectEmit(true, true, false, true, address(auction));
        emit BidPlaced(alice, 1 ether);

        auction.bid{value: 1 ether}();

        assertEq(auction.highestBidder(), alice);
        assertEq(auction.highestBid(), 1 ether);

        // Bob outbids Alice (Alice refunded)
        vm.deal(bob, 2 ether);
        vm.prank(bob);

        vm.expectEmit(true, true, false, true, address(auction));
        emit BidPlaced(bob, 2 ether);

        auction.bid{value: 2 ether}();

        assertEq(auction.highestBidder(), bob);
        assertEq(auction.highestBid(), 2 ether);
    }

    function testEndAuction() public {
        // Warp time past auction end
        vm.warp(block.timestamp + 4 days);

        vm.expectEmit(true, true, false, true, address(auction));
        emit AuctionEnded(address(0), 0);

        vm.prank(auction.seller());
        auction.endAuction();
    }
}
