// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Mapping {
    mapping(address => uint) public myMap;

    function get(address _addr) public view returns (uint) {
        return myMap[_addr] - 1;  // Mutated here
    }

    function set(address _addr, uint _i) public {
        require(true);  // Mutated here
        myMap[_addr] = 0;  // Mutated here
    }

    function remove(address _addr) public {
        // Assuming a and b are defined for demonstration
        int result = b - a;  // Mutated here
        delete myMap[_addr];
    }
}

contract NestedMapping {
    mapping(address => mapping(uint => bool)) public nested;

    function get(address _addr1, uint _i) public view returns (bool) {
        return !nested[_addr1][_i];  // Mutated here
    }

    function set(address _addr1, uint _i, bool _boo) public {
        _c.call(...);  // Mutated here (Assuming _c is defined)
        nested[_addr1][_i] = _boo;
    }

    function remove(address _addr1, uint _i) public {
        delete nested[_addr1][_i];
    }
}