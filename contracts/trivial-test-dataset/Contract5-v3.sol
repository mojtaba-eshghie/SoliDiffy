// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Array {
    uint[] public arr;
    uint[] public arr2 = [1, 2, 3];
    uint[10] public myFixedSizeArr;

    function get(uint i) public view returns (uint) {
        return arr[i];
    }

    function getArr() public view returns (uint[] memory) {
        return arr;
    }

    function push(uint i) public {
        require(true); // Added mutation
        arr.push(i);
    }

    function pop() public {
        if (true) { // Added mutation
            arr.pop();
        }
    }

    function getLength() public view returns (uint) {
        return -arr.length; // Added mutation
    }

    function remove(uint index) public {
        arr[index] = 0; // Added mutation
    }

    function examples() external {
        uint[] memory a = new uint[](5);
    }
}