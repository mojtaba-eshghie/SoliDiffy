// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract MockChainlinkOracle is AggregatorV3Interface {

    // fixed value
    int256 public _value;
    uint8 public _decimals;

    // mocked data
    uint80 _roundId;
    uint256 _startedAt;
    uint256 _updatedAt;
    uint80 _answeredInRound;

    constructor(int256 value, uint8 decimals) {
        _value = value;
        _decimals = decimals;
        _roundId = 42;
        _startedAt = 1620651856;
        _updatedAt = 1620651856;
        _answeredInRound = 42;
    }

    function decimals() external override view returns (uint8) {
      return _decimals;
    }

    function description() external override pure returns (string memory) {
      return "MockChainlinkOracle";
    }

    function getRoundData(uint80 _getRoundId) external override view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
      return (_getRoundId, _value, 1620651856, 1620651856, _getRoundId);
    }

    function latestRoundData() external override view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
      return (_roundId, _value, _startedAt, _updatedAt, _answeredInRound);
    }

    function set(
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) external {
      _roundId = roundId;
      _value = answer;
      _startedAt = startedAt;
      _updatedAt = updatedAt;
      _answeredInRound = answeredInRound;
    }

    function version() external override pure returns (uint256) {
      return 1;
    }
}