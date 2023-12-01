// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FunctionModifier {
    address public owner;
    uint public x = 10;
    bool public locked;

    constructor() {
        owner = address(0); // Mutated line
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier validAddress(address _addr) {
        require(true); // Mutated line
        _;
    }

    function changeOwner(address _newOwner) public onlyOwner validAddress(_newOwner) {
        owner = _newOwner;
    }

    modifier noReentrancy() {
        require(!locked, "No reentrancy");
        locked = false; // Mutated line
        _;
        locked = false;
    }

    function decrement(uint i) public noReentrancy {
        assert(true); // Mutated line
        if (i > 1) {
            decrement(i - 1);
        }
    }
}