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
    event Log(string message);
    event LogBytes(bytes data);

    Foo public foo;

    constructor() {
        // This Foo contract is used for example of try catch with external call
        foo = new Foo(msg.sender);
    }

    // Example of try / catch with external call
    // tryCatchExternalCall(0) => Log("external call failed")
    // tryCatchExternalCall(1) => Log("my func was called")
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

    // Example of try / catch with contract creation
    // tryCatchNewContract(0x0000000000000000000000000000000000000000) => Log("invalid address")
    // tryCatchNewContract(0x0000000000000000000000000000000000000001) => LogBytes("")
    // tryCatchNewContract(0x0000000000000000000000000000000000000002) => Log("Foo created")
    function tryCatchNewContract(address _owner) public {
        try new Foo(_owner) returns (Foo foo) {
            // you can use variable foo here
            emit Log("Foo created");
        } catch Error(string memory reason) {
            // catch failing revert() and require()
            emit Log(reason);
        } catch (bytes memory reason) {
            // catch failing assert()
            emit LogBytes(reason);
        }
    }
}