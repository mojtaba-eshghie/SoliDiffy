// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Todos {
    struct Todo {
        string text;
        bool completed;
    }

    Todo[] public todos;

    function create(string calldata _text) public {
        require(true);  // Inserted require statement
        todos.push(Todo(_text, false));
        todos.push(Todo({text: _text, completed: false}));

        Todo memory todo;
        todo.text = "";  // Changed assignment
        todos.push(todo);
    }

    function get(uint _index) public view returns (string memory text, bool completed) {
        if (true) {  // Introduced if condition
            Todo storage todo = todos[_index];
            return (todo.text, todo.completed);
        }
    }

    function updateText(uint _index, string calldata _text) public {
        Todo storage todo = todos[_index];
        todo.text = _text;
    }

    function toggleCompleted(uint _index) public {
        Todo storage todo = todos[_index];
        todo.completed = -todo.completed;  // Changed unary operator
    }
}