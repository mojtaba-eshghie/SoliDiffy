// SPDX-License-Identifier: MIT
pragma solidity >=0.6.10 <0.8.0;

interface ITranchessSwapCallee {
    function tranchessSwapCallback(
        uint256 baseDeltaOut,
        uint256 quoteDeltaOut,
        bytes calldata data
    ) external;
}
