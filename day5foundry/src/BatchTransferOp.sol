pragma solidity ^0.8.13;

contract BatchTransferOp {

   function SendEthOp(address []  calldata recipients, uint256 amount) external payable{
      uint256 length = recipients.length;
      require(msg.value == length * amount, "incorrect Eth sent");

      for (uint256 i; i < length;){
         (bool sent,) = recipients[i].call{value: amount}("");
         require(sent, "Transfer failed");
         unchecked{i++;} // save gas on increment
     }
     
   } 

}