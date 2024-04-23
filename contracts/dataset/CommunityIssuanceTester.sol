// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "../LQTY/CommunityIssuance.sol";

contract CommunityIssuanceTester is CommunityIssuance {
    function obtainLQTY(uint _amount) external {
        lqtyToken.transfer(msg.sender, _amount);
    }

    function setDeploymentTime() external {
        deploymentTime = block.timestamp;
    }

    function getCumulativeIssuanceFraction() external view returns (uint) {
       return _getCumulativeIssuanceFraction();
    }

    function unprotectedIssueLQTY() external returns (uint) {
        // No checks on caller address
       
        uint latestTotalLQTYIssued = LQTYSupplyCap.mul(_getCumulativeIssuanceFraction()).div(1e18);
        uint issuance = latestTotalLQTYIssued.sub(totalLQTYIssued);
      
        totalLQTYIssued = latestTotalLQTYIssued;
        return issuance;
    }
}
