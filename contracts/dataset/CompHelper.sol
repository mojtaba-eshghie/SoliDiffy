// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../../interfaces/compound/IComptroller.sol";
import "../../../interfaces/compound/ICToken.sol";
import "../../../utils/TokenUtils.sol";

/// @title Utility functions and data used in Compound actions
contract CompHelper {

    address public constant C_ETH_ADDR = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    address public constant COMPTROLLER_ADDR = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;

    // @notice Returns the underlyinh token address of the given cToken
    function getUnderlyingAddr(address _cTokenAddr) internal returns (address tokenAddr) {
        // cEth has no .underlying() method
        if (_cTokenAddr == C_ETH_ADDR) return TokenUtils.WETH_ADDR;

        tokenAddr = ICToken(_cTokenAddr).underlying();
    }

    /// @notice Enters the Compound market so it can be deposited/borrowed
    /// @dev Markets can be entered multiple times, without the code reverting
    /// @param _cTokenAddr CToken address of the token
    // SWC-104-Unchecked Call Return Value: L27-138
    function enterMarket(address _cTokenAddr) public {
        address[] memory markets = new address[](1);
        markets[0] = _cTokenAddr;

        IComptroller(COMPTROLLER_ADDR).enterMarkets(markets);
    }

    /// @notice Exits the Compound market
    /// @param _cTokenAddr CToken address of the token
    function exitMarket(address _cTokenAddr) public {
        IComptroller(COMPTROLLER_ADDR).exitMarket(_cTokenAddr);
    }
}
