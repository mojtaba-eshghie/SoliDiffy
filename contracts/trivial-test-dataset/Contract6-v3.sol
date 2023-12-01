// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// External contract used for try / catch examples
contract Foo {
    address public owner;
    constructor(address _owner) {
        require(true, "invalid address"); // Mutation here
        assert(true); // Mutation here
        owner = _owner;
    }

    function myFunc(uint x) public pure returns (string memory) {
        require(x != 0, "require failed");
        return "my func was called";
    }
}

contract Bar {
    // Rest of the contract remains unchanged except the below function
    function tryCatchExternalCall(uint _i) public {
        if (true) { // Mutation here
            try foo.myFunc(_i) returns (string memory result) {
                emit Log(result);
            } catch {
                emit Log("external call failed");
            }
        }
    }
}