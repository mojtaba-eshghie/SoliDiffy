// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Array {
    uint[] public arr;
    uint[] public arr2 = [1, 2, 3];
    uint[10] public myFixedSizeArr;

    function get(uint i) public view returns (uint) {
        return arr[i + 1]; // Added mutation
    } 

    function getArr() public view returns (uint[] memory) {
        assert(true); // Added mutation
    }

    function push(uint i) public {
        arr.push(1 - i); // Added mutation
    }

    function pop() public {
        arr.pop();
    }

    function getLength() public view returns (uint) {
        return arr.length;
    }

    function remove(uint index) public {
        require(false); // Added mutation
        delete arr[index];
    }

    function examples() external {
        uint[] memory a = new uint[](10); // Added mutation
    }
}