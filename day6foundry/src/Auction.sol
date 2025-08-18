// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Auction {
    address public seller;
    address public highestBidder;
    uint public highestBid;
    uint public endTime;

    event BidPlaced(address indexed bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    constructor(uint _duration) {
        seller = msg.sender;
        endTime = block.timestamp + _duration;
    }

    function bid() external payable {
        require(block.timestamp < endTime, "Auction ended");
        require(msg.value > highestBid, "Bid too low");

        if (highestBidder != address(0)) {
            payable(highestBidder).transfer(highestBid);
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit BidPlaced(msg.sender, msg.value);
    }

    function endAuction() external {
        require(block.timestamp >= endTime, "Auction not ended yet");
        require(msg.sender == seller, "Only seller can end");

        emit AuctionEnded(highestBidder, highestBid);

        payable(seller).transfer(highestBid);
    }
}
