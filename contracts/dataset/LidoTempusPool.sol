// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "../TempusPool.sol";
import "../protocols/lido/ILido.sol";

contract LidoTempusPool is TempusPool {
    ILido internal immutable lido;
    bytes32 public immutable override protocolName = "Lido";
    address private immutable referrer;

    constructor(
        ILido token,
        address controller,
        uint256 maturity,
        uint256 estYield,
        string memory principalName,
        string memory principalSymbol,
        string memory yieldName,
        string memory yieldSymbol,
        address referrerAddress
    )
        TempusPool(
            address(token),
            address(0),
            controller,
            maturity,
            updateInterestRate(address(token)),
            estYield,
            principalName,
            principalSymbol,
            yieldName,
            yieldSymbol
        )
    {
        // TODO: consider adding sanity check for _lido.name() and _lido.symbol()
        lido = token;
        referrer = referrerAddress;
    }

    function depositToUnderlying(uint256 amount) internal override returns (uint256) {
        require(msg.value == amount, "ETH value does not match provided amount");

        uint256 preDepositBalance = IERC20(yieldBearingToken).balanceOf(address(this));
        lido.submit{value: msg.value}(referrer);

        /// TODO: figure out why lido.submit returns a different value than this
        uint256 mintedTokens = IERC20(yieldBearingToken).balanceOf(address(this)) - preDepositBalance;

        return mintedTokens;
    }

    function withdrawFromUnderlyingProtocol(uint256, address)
        internal
        pure
        override
        returns (uint256 backingTokenAmount)
    {
        require(false, "LidoTempusPool.withdrawFromUnderlyingProtocol not supported");
        return 0;
    }

    /// @return Updated current Interest Rate as an 1e18 decimal
    function updateInterestRate(address token) internal view override returns (uint256) {
        return storedInterestRate(token);
    }

    // @return Stored Interest Rate as an 1e18 decimal
    function storedInterestRate(address token) internal view override returns (uint256) {
        // NOTE: if totalShares() is 0, then rate is also 0,
        //       but this only happens right after deploy, so we ignore it
        return ILido(token).getPooledEthByShares(1e18);
    }

    /// NOTE: Lido StETH is pegged 1:1 to ETH
    /// @return Asset Token amount
    function numAssetsPerYieldToken(uint yieldTokens, uint) public pure override returns (uint) {
        return yieldTokens;
    }

    /// NOTE: Lido StETH is pegged 1:1 to ETH
    /// @return YBT amount
    function numYieldTokensPerAsset(uint backingTokens, uint) public pure override returns (uint) {
        return backingTokens;
    }
}
