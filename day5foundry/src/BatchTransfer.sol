// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract BatchTransfer {

    function TransferEth (address [] calldata recipients, uint256 amount) external payable {
        require (msg.value == recipients.length * amount, "incorrect Eth sent");
        for(uint256 i = 0; i < recipients.length; i++){
            payable(recipients[i]).transfer(amount);

        }
    }

} 
   
