// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";

/**
 * @title Crowdfund
 * @dev A crowdfunding platform built with Foundry
 * @notice This contract integrates all concepts from the 15-day Foundry bootcamp
 */
contract Crowdfund is Ownable, ReentrancyGuard {
    // Campaign structure
    struct Campaign {
        uint256 id;
        address creator;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        uint256 totalContributors;
        string imageHash;
        bool exists;
        bool completed;
    }

    // Contribution structure
    struct Contribution {
        address contributor;
        uint256 amount;
        uint256 timestamp;
    }

    // State variables
    uint256 public campaignCount;
    uint256 public platformFee; // in basis points (100 = 1%)
    address public feeRecipient;
    
    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => Contribution[]) public contributions;
    mapping(uint256 => mapping(address => uint256)) public userContributions;
    mapping(address => uint256[]) public userCampaigns;

    // Events
    event CampaignCreated(
        uint256 indexed id,
        address indexed creator,
        string title,
        uint256 target,
        uint256 deadline
    );

    event ContributionMade(
        uint256 indexed campaignId,
        address indexed contributor,
        uint256 amount
    );

    event FundsWithdrawn(
        uint256 indexed campaignId,
        address indexed creator,
        uint256 amount
    );

    event CampaignCompleted(uint256 indexed campaignId, bool success);
    event PlatformFeeUpdated(uint256 newFee);
    event FeeRecipientUpdated(address newRecipient);

    // Custom errors (Gas optimization - Day 5)
    error CampaignNotFound();
    error CampaignAlreadyExists();
    error InvalidTarget();
    error InvalidDeadline();
    error CampaignEnded();
    error CampaignNotEnded();
    error InvalidContribution();
    error TargetNotReached();
    error AlreadyWithdrawn();
    error TransferFailed();
    error InvalidFee();
    error NotCampaignCreator();
    error TargetReached();
    error NoContribution();

    modifier campaignExists(uint256 _campaignId) {
        if (!campaigns[_campaignId].exists) revert CampaignNotFound();
        _;
    }

    modifier onlyCampaignCreator(uint256 _campaignId) {
        if (msg.sender != campaigns[_campaignId].creator) revert NotCampaignCreator();
        _;
    }

    constructor(uint256 _platformFee, address _feeRecipient) {
        platformFee = _platformFee;
        feeRecipient = _feeRecipient;
    }

    /**
     * @dev Create a new crowdfunding campaign
     * @param _title Campaign title
     * @param _description Campaign description
     * @param _target Funding target in wei
     * @param _deadline Campaign deadline timestamp
     * @param _imageHash IPFS hash for campaign image
     */
    function createCampaign(
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _imageHash
    ) external returns (uint256) {
        if (_target == 0) revert InvalidTarget();
        if (_deadline <= block.timestamp) revert InvalidDeadline();

        campaignCount++;
        uint256 campaignId = campaignCount;

        campaigns[campaignId] = Campaign({
            id: campaignId,
            creator: msg.sender,
            title: _title,
            description: _description,
            target: _target,
            deadline: _deadline,
            amountCollected: 0,
            totalContributors: 0,
            imageHash: _imageHash,
            exists: true,
            completed: false
        });

        userCampaigns[msg.sender].push(campaignId);

        emit CampaignCreated(campaignId, msg.sender, _title, _target, _deadline);
        return campaignId;
    }

    /**
     * @dev Contribute to a campaign
     * @param _campaignId ID of the campaign to contribute to
     */
    function contribute(uint256 _campaignId) 
        external 
        payable 
        nonReentrant 
        campaignExists(_campaignId)
    {
        Campaign storage campaign = campaigns[_campaignId];
        
        if (block.timestamp > campaign.deadline) revert CampaignEnded();
        if (msg.value == 0) revert InvalidContribution();

        if (userContributions[_campaignId][msg.sender] == 0) {
            campaign.totalContributors++;
        }

        campaign.amountCollected += msg.value;
        userContributions[_campaignId][msg.sender] += msg.value;

        contributions[_campaignId].push(Contribution({
            contributor: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        }));

        emit ContributionMade(_campaignId, msg.sender, msg.value);
    }

    /**
     * @dev Withdraw funds if campaign is successful
     * @param _campaignId ID of the campaign to withdraw from
     */
    function withdrawFunds(uint256 _campaignId) 
        external 
        nonReentrant 
        campaignExists(_campaignId)
        onlyCampaignCreator(_campaignId)
    {
        Campaign storage campaign = campaigns[_campaignId];
        
        if (block.timestamp <= campaign.deadline) revert CampaignNotEnded();
        if (campaign.completed) revert AlreadyWithdrawn();
        if (campaign.amountCollected < campaign.target) revert TargetNotReached();

        campaign.completed = true;
        uint256 amount = campaign.amountCollected;
        uint256 fee = (amount * platformFee) / 10000;
        uint256 netAmount = amount - fee;

        // Transfer fee to platform
        if (fee > 0) {
            (bool feeSuccess, ) = payable(feeRecipient).call{value: fee}("");
            if (!feeSuccess) revert TransferFailed();
        }

        // Transfer funds to creator
        (bool success, ) = payable(campaign.creator).call{value: netAmount}("");
        if (!success) revert TransferFailed();

        emit FundsWithdrawn(_campaignId, campaign.creator, netAmount);
        emit CampaignCompleted(_campaignId, true);
    }

    /**
     * @dev Refund contribution if campaign fails
     * @param _campaignId ID of the campaign to get refund from
     */
    function refund(uint256 _campaignId) 
        external 
        nonReentrant 
        campaignExists(_campaignId)
    {
        Campaign storage campaign = campaigns[_campaignId];
        
        if (block.timestamp <= campaign.deadline) revert CampaignNotEnded();
        if (campaign.amountCollected >= campaign.target) revert TargetReached();

        uint256 userContribution = userContributions[_campaignId][msg.sender];
        if (userContribution == 0) revert NoContribution();

        userContributions[_campaignId][msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: userContribution}("");
        if (!success) revert TransferFailed();

        emit CampaignCompleted(_campaignId, false);
    }

    // View functions
    function getCampaign(uint256 _campaignId) 
        external 
        view 
        campaignExists(_campaignId) 
        returns (Campaign memory)
    {
        return campaigns[_campaignId];
    }

    function getContributions(uint256 _campaignId) 
        external 
        view 
        campaignExists(_campaignId) 
        returns (Contribution[] memory)
    {
        return contributions[_campaignId];
    }

    function getUserContribution(uint256 _campaignId, address _user) 
        external 
        view 
        campaignExists(_campaignId) 
        returns (uint256)
    {
        return userContributions[_campaignId][_user];
    }

    function getUserCampaigns(address _user) 
        external 
        view 
        returns (uint256[] memory)
    {
        return userCampaigns[_user];
    }

    function getActiveCampaigns() external view returns (Campaign[] memory) {
        uint256 activeCount;
        for (uint256 i = 1; i <= campaignCount; i++) {
            if (campaigns[i].exists && !campaigns[i].completed && block.timestamp <= campaigns[i].deadline) {
                activeCount++;
            }
        }

        Campaign[] memory activeCampaigns = new Campaign[](activeCount);
        uint256 currentIndex;
        for (uint256 i = 1; i <= campaignCount; i++) {
            if (campaigns[i].exists && !campaigns[i].completed && block.timestamp <= campaigns[i].deadline) {
                activeCampaigns[currentIndex] = campaigns[i];
                currentIndex++;
            }
        }

        return activeCampaigns;
    }

    // Admin functions
    function setPlatformFee(uint256 _newFee) external onlyOwner {
        if (_newFee > 1000) revert InvalidFee(); // Max 10% fee
        platformFee = _newFee;
        emit PlatformFeeUpdated(_newFee);
    }

    function setFeeRecipient(address _newRecipient) external onlyOwner {
        feeRecipient = _newRecipient;
        emit FeeRecipientUpdated(_newRecipient);
    }
}
