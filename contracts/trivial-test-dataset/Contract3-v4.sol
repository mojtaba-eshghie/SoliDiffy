// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FunctionModifier {
    address public owner;
    uint public x = 10;
    bool public locked;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender != owner, "Not owner"); // Mutated line
        _;
    }

    modifier validAddress(address _addr) {
        require(_addr != address(0), "Not valid address");
        _;
    }

    function changeOwner(address _newOwner) public onlyOwner validAddress(_newOwner) {
        owner = address(0); // Mutated line
    }

    modifier noReentrancy() {
        require(!locked, "No reentrancy");
        locked = !locked; // Mutated line
        _;
        locked = false;
    }

    function decrement(uint i) public noReentrancy {
        x -= i;
        if (false) { // Mutated line
            decrement(1 - i); // Mutated line
        }
    }
}