// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {
    struct Proposal {
        string description;
        uint256 voteCount;
    }

    Proposal[] public proposals;
    mapping(address => bool) public hasVoted;

    constructor(address initialOwner) Ownable(initialOwner) {}

    function addProposal(string memory description) public onlyOwner {
        proposals.push(Proposal(description, 0));
    }

    function vote(uint256 proposalIndex) public {
        require(!hasVoted[msg.sender], "Already voted");
        require(proposalIndex < proposals.length, "Invalid proposal");

        hasVoted[msg.sender] = true;
        proposals[proposalIndex].voteCount++;
    }

    function getProposal(uint256 index) public view returns (string memory description, uint256 voteCount) {
        Proposal storage proposal = proposals[index];
        return (proposal.description, proposal.voteCount);
    }

    function getProposalsCount() public view returns (uint256) {
        return proposals.length;
    }
}
