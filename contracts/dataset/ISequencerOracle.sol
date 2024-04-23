// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

/**
 * @title ISequencerOracle
 * @author Aave
 * @notice Defines the basic interface for a Sequencer oracle.
 */
interface ISequencerOracle {
  function latestAnswer() external view returns (bool, uint256);
}
