// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * @title MonthlySubscription
 * @dev A contract for managing monthly subscriptions with automatic payments
 * @notice Users can subscribe, cancel, and make monthly payments
 */
contract MonthlySubscription {
    struct Subscription {
        address subscriber;
        uint256 startTime;
        uint256 lastPaymentTime;
        uint256 monthlyRate;
        bool isActive;
    }

    address public owner;
    uint256 public totalSubscriptions;
    mapping(address => Subscription) public subscriptions;
    mapping(address => bool) public isSubscriber;

    event SubscriptionCreated(address indexed subscriber, uint256 monthlyRate, uint256 startTime);
    event PaymentReceived(address indexed subscriber, uint256 amount, uint256 paymentTime);
    event SubscriptionCancelled(address indexed subscriber, uint256 cancelTime);
    event FundsWithdrawn(address indexed owner, uint256 amount, uint256 withdrawTime);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlySubscriber() {
        require(isSubscriber[msg.sender], "Only subscribers can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Subscribe to the monthly service
     * @param _monthlyRate Monthly subscription rate in wei
     */
    function subscribe(uint256 _monthlyRate) external payable {
        require(!isSubscriber[msg.sender], "Already subscribed");
        require(_monthlyRate > 0, "Monthly rate must be greater than 0");
        require(msg.value == _monthlyRate, "Initial payment must equal monthly rate");

        subscriptions[msg.sender] = Subscription({
            subscriber: msg.sender,
            startTime: block.timestamp,
            lastPaymentTime: block.timestamp,
            monthlyRate: _monthlyRate,
            isActive: true
        });

        isSubscriber[msg.sender] = true;
        totalSubscriptions++;

        emit SubscriptionCreated(msg.sender, _monthlyRate, block.timestamp);
        emit PaymentReceived(msg.sender, _monthlyRate, block.timestamp);
    }

    /**
     * @dev Make monthly payment
     */
    function makePayment() external payable onlySubscriber {
        Subscription storage sub = subscriptions[msg.sender];
        require(sub.isActive, "Subscription is not active");
        
        uint256 daysSinceLastPayment = (block.timestamp - sub.lastPaymentTime) / 1 days;
        require(daysSinceLastPayment >= 28, "Too early for next payment");
        
        require(msg.value == sub.monthlyRate, "Payment amount must equal monthly rate");

        sub.lastPaymentTime = block.timestamp;

        emit PaymentReceived(msg.sender, msg.value, block.timestamp);
    }

    /**
     * @dev Cancel subscription
     */
    function cancelSubscription() external onlySubscriber {
        Subscription storage sub = subscriptions[msg.sender];
        require(sub.isActive, "Subscription already cancelled");

        sub.isActive = false;
        isSubscriber[msg.sender] = false;
        totalSubscriptions--;

        emit SubscriptionCancelled(msg.sender, block.timestamp);
    }

    /**
     * @dev Check if subscription is active and paid up
     */
    function isSubscriptionActive(address _subscriber) external view returns (bool) {
        Subscription memory sub = subscriptions[_subscriber];
        if (!sub.isActive) return false;
        
        uint256 daysSinceLastPayment = (block.timestamp - sub.lastPaymentTime) / 1 days;
        return daysSinceLastPayment <= 35; // 7-day grace period
    }

    /**
     * @dev Get subscription details
     */
    function getSubscription(address _subscriber) external view returns (
        address subscriber,
        uint256 startTime,
        uint256 lastPaymentTime,
        uint256 monthlyRate,
        bool isActive
    ) {
        Subscription memory sub = subscriptions[_subscriber];
        return (
            sub.subscriber,
            sub.startTime,
            sub.lastPaymentTime,
            sub.monthlyRate,
            sub.isActive
        );
    }

    /**
     * @dev Withdraw collected funds (owner only)
     */
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        payable(owner).transfer(balance);

        emit FundsWithdrawn(owner, balance, block.timestamp);
    }

    /**
     * @dev Get contract balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Emergency stop for owner to cancel any subscription
     */
    function emergencyCancel(address _subscriber) external onlyOwner {
        Subscription storage sub = subscriptions[_subscriber];
        if (sub.isActive) {
            sub.isActive = false;
            isSubscriber[_subscriber] = false;
            totalSubscriptions--;
            emit SubscriptionCancelled(_subscriber, block.timestamp);
        }
    }
}
