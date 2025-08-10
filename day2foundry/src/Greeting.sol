// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Greeting {
    string public greeting;

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }

    function getGreeting() public view returns(string memory){
        return greeting;
    }
    
}
