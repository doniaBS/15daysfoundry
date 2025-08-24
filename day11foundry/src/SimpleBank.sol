// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract SimpleBank {
    mapping(address => uint256) private balances;

    // Deposit ETH to the bank
    function deposit() external payable {
        require(msg.value > 0, "Must deposit more than 0");
        balances[msg.sender] += msg.value;
    }

    // Withdraw ETH from the bank
    function withdraw(uint256 amount) external {
        require(amount > 0, "Withdraw amount must be greater than zero");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    // Check balance of the caller
    function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }
}
