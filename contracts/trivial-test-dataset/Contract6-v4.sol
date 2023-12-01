// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// External contract used for try / catch examples
contract Foo {
    address public owner;
    constructor(address _owner) {
        require(address(0) != _owner, "invalid address"); // Mutation here
        assert(_owner == 0x0000000000000000000000000000000000000001); // Mutation here
        owner = address(1); // Mutation here
    }

    function myFunc(uint x) public pure returns (string memory) {
        require(false, "require failed"); // Mutation here
        return "my func was called";
    }
}

contract Bar {
    // Rest of the contract remains unchanged except the below function
    function tryCatchNewContract(address _owner) public {
        if (false) { // Mutation here
            try new Foo(_owner) returns (Foo foo) {
                emit Log("Foo created");
            } catch Error(string memory reason) {
                emit Log(reason);
            } catch (bytes memory reason) {
                emit LogBytes(reason);
            }
        }
    }
}