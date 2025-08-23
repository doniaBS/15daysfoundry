// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract SimpleBank {
    mapping(address => uint256) private balances;

    function deposit() external payable {
        require(msg.value > 0, "Deposit must be > 0");
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Not enough balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }
}
