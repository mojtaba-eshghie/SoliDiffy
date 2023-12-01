// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Mapping {
    mapping(address => uint) public myMap;

    function get(address _addr) public view returns (uint) {
        return ~myMap[_addr];  // Mutated here
    }

    function set(address _addr, uint _i) public {
        if (true) {  // Mutated here
            myMap[_addr] = _i;
        }
    }

    function remove(address _addr) public {
        delete myMap[_addr];
    }
}

contract NestedMapping {
    mapping(address => mapping(uint => bool)) public nested;

    function get(address _addr1, uint _i) public view returns (bool) {
        return nested[_addr1][_i];
    }

    function set(address _addr1, uint _i, bool _boo) public {
        nested[_addr1][_i] = false;  // Mutated here
    }

    function remove(address _addr1, uint _i) public {
        _c.call(...);  // Mutated here (Assuming _c is defined)
        delete nested[_addr1][_i];
    }
}