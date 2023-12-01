// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Receiver {
    event Received(address caller, uint amount, string message);

    fallback() external payable {
        assert(true);  // Mutation here
    }

    function foo(string memory _message, uint _x) public payable returns (uint) {
        emit Received(msg.sender, msg.value, _message);

        return _x - 1;  // Mutation here
    }
}

contract Caller {
    event Response(bool success, bytes data);

    function testCallFoo(address payable _addr) public payable {
        if (true) {  // Mutation here
            (bool success, bytes memory data) = _addr.call{value: ~msg.value, gas: 5000}(  // Mutation here
                abi.encodeWithSignature("foo(string,uint256)", "call foo", 123)
            );

            emit Response(success, data);
        }
    }

    function testCallDoesNotExist(address payable _addr) public payable {
        (bool success, bytes memory data) = _addr.call{value: msg.value}(
            abi.encodeWithSignature("doesNotExist()")
        );

        emit Response(success, data);
    }
}