// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-solidity-utils/contracts/math/FixedPoint.sol";
import "@balancer-labs/v2-solidity-utils/contracts/helpers/InputHelpers.sol";
import "@balancer-labs/v2-solidity-utils/contracts/helpers/WordCodec.sol";

import "@balancer-labs/v2-pool-utils/contracts/BaseGeneralPool.sol";
import "@balancer-labs/v2-pool-utils/contracts/BaseMinimalSwapInfoPool.sol";

import "./interfaces/IRateProvider.sol";
import "./../ITempusPool.sol";
import "./../token/IPoolShare.sol";
import "./StableMath.sol";
import "./TempusAMMUserDataHelpers.sol";

contract TempusAMM is BaseGeneralPool, BaseMinimalSwapInfoPool, StableMath, IRateProvider {
    using WordCodec for bytes32;
    using FixedPoint for uint256;
    using TempusAMMUserDataHelpers for bytes;

    // This contract uses timestamps to slowly update its Amplification parameter over time. These changes must occur
    // over a minimum time period much larger than the blocktime, making timestamp manipulation a non-issue.
    // solhint-disable not-rely-on-time

    // Amplification factor changes must happen over a minimum period of one day, and can at most divide or multiple the
    // current value by 2 every day.
    // WARNING: this only limits *a single* amplification change to have a maximum rate of change of twice the original
    // value daily. It is possible to perform multiple amplification changes in sequence to increase this value more
    // rapidly: for example, by doubling the value every day it can increase by a factor of 8 over three days (2^3).
    uint256 private constant _MIN_UPDATE_TIME = 1 days;
    uint256 private constant _MAX_AMP_UPDATE_DAILY_RATE = 2;
    uint256 private constant _TEMPUS_SHARE_PRECISION = 1e18;

    bytes32 private _packedAmplificationData;

    event AmpUpdateStarted(uint256 startValue, uint256 endValue, uint256 startTime, uint256 endTime);
    event AmpUpdateStopped(uint256 currentValue);

    uint256 private immutable _totalTokens;

    IPoolShare internal immutable _token0;
    IPoolShare internal immutable _token1;

    // All token balances are normalized to behave as if the token had 18 decimals. We assume a token's decimals will
    // not change throughout its lifetime, and store the corresponding scaling factor for each at construction time.
    // These factors are always greater than or equal to one: tokens with more than 18 decimals are not supported.

    uint256 internal immutable _scalingFactor0;
    uint256 internal immutable _scalingFactor1;

    // To track how many tokens are owed to the Vault as protocol fees, we measure and store the value of the invariant
    // after every join and exit. All invariant growth that happens between join and exit events is due to swap fees.
    uint256 internal _lastInvariant;

    // Because the invariant depends on the amplification parameter, and this value may change over time, we should only
    // compare invariants that were computed using the same value. We therefore store it whenever we store
    // _lastInvariant.
    uint256 internal _lastInvariantAmp;

    ITempusPool public immutable tempusPool;

    enum JoinKind {
        INIT,
        EXACT_TOKENS_IN_FOR_BPT_OUT,
        TOKEN_IN_FOR_EXACT_BPT_OUT
    }
    enum ExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        EXACT_BPT_IN_FOR_TOKENS_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT
    }

    constructor(
        IVault vault,
        string memory name,
        string memory symbol,
        ITempusPool pool,
        uint256 amplificationParameter,
        uint256 swapFeePercentage,
        uint256 pauseWindowDuration,
        uint256 bufferPeriodDuration,
        address owner
    )
        BasePool(
            vault,
            // Because we're inheriting from both BaseGeneralPool and BaseMinimalSwapInfoPool we can choose any
            // specialization setting. Since this Pool never registers or deregisters any tokens after construction,
            // picking Two Token when the Pool only has two tokens is free gas savings.
            IVault.PoolSpecialization.TWO_TOKEN,
            name,
            symbol,
            _mapTempusSharesToIERC20(pool),
            new address[](2),
            swapFeePercentage,
            pauseWindowDuration,
            bufferPeriodDuration,
            owner
        )
    {
        _require(amplificationParameter >= _MIN_AMP, Errors.MIN_AMP);
        _require(amplificationParameter <= _MAX_AMP, Errors.MAX_AMP);

        _totalTokens = 2;

        // Immutable variables cannot be initialized inside an if statement, so we must do conditional assignments
        IPoolShare yieldShare = pool.yieldShare();
        IPoolShare principalShare = pool.principalShare();
        (_token0, _token1) = yieldShare < principalShare ? (yieldShare, principalShare) : (principalShare, yieldShare);

        tempusPool = pool;

        _scalingFactor0 = _computeScalingFactor(IERC20(address(yieldShare)));
        _scalingFactor1 = _computeScalingFactor(IERC20(address(principalShare)));

        uint256 initialAmp = Math.mul(amplificationParameter, _AMP_PRECISION);
        _setAmplificationData(initialAmp);
    }

    modifier beforeMaturity() {
        require(!tempusPool.matured(), "Pool already finalized!");
        _;
    }

    function getLastInvariant() external view returns (uint256 lastInvariant, uint256 lastInvariantAmp) {
        lastInvariant = _lastInvariant;
        lastInvariantAmp = _lastInvariantAmp;
    }

    // Base Pool handlers

    // Swap - General Pool specialization (from BaseGeneralPool)

    function _onSwapGivenIn(
        SwapRequest memory swapRequest,
        uint256[] memory balances,
        uint256 indexIn,
        uint256 indexOut
    ) internal virtual override whenNotPaused beforeMaturity returns (uint256) {
        (uint256 currentAmp, ) = _getAmplificationParameter();
        (IPoolShare tokenIn, IPoolShare tokenOut) = indexIn == 0 ? (_token0, _token1) : (_token1, _token0);

        _rateAdjustBalances(balances);
        uint256 rateAdjustedSwapAmount = (swapRequest.amount * tokenIn.getPricePerFullShare()) /
            _TEMPUS_SHARE_PRECISION;

        uint256 amountOut = StableMath._calcOutGivenIn(currentAmp, balances, indexIn, indexOut, rateAdjustedSwapAmount);
        amountOut = (amountOut * _TEMPUS_SHARE_PRECISION) / tokenOut.getPricePerFullShare();

        return amountOut;
    }

    function _onSwapGivenOut(
        SwapRequest memory swapRequest,
        uint256[] memory balances,
        uint256 indexIn,
        uint256 indexOut
    ) internal virtual override whenNotPaused beforeMaturity returns (uint256) {
        (uint256 currentAmp, ) = _getAmplificationParameter();
        (IPoolShare tokenIn, IPoolShare tokenOut) = indexIn == 0 ? (_token0, _token1) : (_token1, _token0);

        _rateAdjustBalances(balances);
        uint256 rateAdjustedSwapAmount = (swapRequest.amount * tokenOut.getPricePerFullShare()) /
            _TEMPUS_SHARE_PRECISION;

        uint256 amountIn = StableMath._calcInGivenOut(currentAmp, balances, indexIn, indexOut, rateAdjustedSwapAmount);
        amountIn = (amountIn * _TEMPUS_SHARE_PRECISION) / tokenIn.getPricePerFullShare();

        return amountIn;
    }

    // Swap - Two Token Pool specialization (from BaseMinimalSwapInfoPool)

    function _onSwapGivenIn(
        SwapRequest memory swapRequest,
        uint256 balanceTokenIn,
        uint256 balanceTokenOut
    ) internal virtual override returns (uint256) {
        _require(_getTotalTokens() == 2, Errors.NOT_TWO_TOKENS);

        (uint256[] memory balances, uint256 indexIn, uint256 indexOut) = _getSwapBalanceArrays(
            swapRequest,
            balanceTokenIn,
            balanceTokenOut
        );

        return _onSwapGivenIn(swapRequest, balances, indexIn, indexOut);
    }

    function _onSwapGivenOut(
        SwapRequest memory swapRequest,
        uint256 balanceTokenIn,
        uint256 balanceTokenOut
    ) internal virtual override returns (uint256) {
        _require(_getTotalTokens() == 2, Errors.NOT_TWO_TOKENS);

        (uint256[] memory balances, uint256 indexIn, uint256 indexOut) = _getSwapBalanceArrays(
            swapRequest,
            balanceTokenIn,
            balanceTokenOut
        );
        return _onSwapGivenOut(swapRequest, balances, indexIn, indexOut);
    }

    function _getSwapBalanceArrays(
        SwapRequest memory swapRequest,
        uint256 balanceTokenIn,
        uint256 balanceTokenOut
    )
        private
        view
        returns (
            uint256[] memory balances,
            uint256 indexIn,
            uint256 indexOut
        )
    {
        balances = new uint256[](2);

        if (address(_token0) == address(swapRequest.tokenIn)) {
            indexIn = 0;
            indexOut = 1;

            balances[0] = balanceTokenIn;
            balances[1] = balanceTokenOut;
        } else {
            // _token0 == swapRequest.tokenOut
            indexOut = 0;
            indexIn = 1;

            balances[0] = balanceTokenOut;
            balances[1] = balanceTokenIn;
        }
    }

    // Initialize

    function _onInitializePool(
        bytes32,
        address,
        address,
        uint256[] memory scalingFactors,
        bytes memory userData
    ) internal virtual override whenNotPaused beforeMaturity returns (uint256, uint256[] memory) {
        // It would be strange for the Pool to be paused before it is initialized, but for consistency we prevent
        // initialization in this case.
        TempusAMM.JoinKind kind = userData.joinKind();
        _require(kind == TempusAMM.JoinKind.INIT, Errors.UNINITIALIZED);

        uint256[] memory amountsIn = userData.initialAmountsIn();
        InputHelpers.ensureInputLengthMatch(amountsIn.length, _getTotalTokens());
        _upscaleArray(amountsIn, scalingFactors);

        _rateAdjustBalances(amountsIn);
        (uint256 currentAmp, ) = _getAmplificationParameter();
        uint256 invariantAfterJoin = StableMath._calculateInvariant(currentAmp, amountsIn, true);

        // Set the initial BPT to the value of the invariant.
        uint256 bptAmountOut = invariantAfterJoin;

        _updateLastInvariant(invariantAfterJoin, currentAmp);

        _undoRateAdjustBalances(amountsIn);

        return (bptAmountOut, amountsIn);
    }

    // Join

    function _onJoinPool(
        bytes32,
        address,
        address,
        uint256[] memory balances,
        uint256,
        uint256 protocolSwapFeePercentage,
        uint256[] memory scalingFactors,
        bytes memory userData
    )
        internal
        virtual
        override
        whenNotPaused
        beforeMaturity
        returns (
            uint256,
            uint256[] memory,
            uint256[] memory
        )
    {
        _rateAdjustBalances(balances);

        // Due protocol swap fee amounts are computed by measuring the growth of the invariant between the previous join
        // or exit event and now - the invariant's growth is due exclusively to swap fees. This avoids spending gas to
        // calculate the fee amounts during each individual swap.
        uint256[] memory dueProtocolFeeAmounts = _getDueProtocolFeeAmounts(balances, protocolSwapFeePercentage);

        // Update current balances by subtracting the protocol fee amounts
        _mutateAmounts(balances, dueProtocolFeeAmounts, FixedPoint.sub);
        (uint256 bptAmountOut, uint256[] memory amountsIn) = _doJoin(balances, scalingFactors, userData);

        // Update the invariant with the balances the Pool will have after the join, in order to compute the
        // protocol swap fee amounts due in future joins and exits.
        _updateInvariantAfterJoin(balances, amountsIn);

        _undoRateAdjustBalances(amountsIn);
        _undoRateAdjustBalances(dueProtocolFeeAmounts);

        return (bptAmountOut, amountsIn, dueProtocolFeeAmounts);
    }

    function _doJoin(
        uint256[] memory balances,
        uint256[] memory scalingFactors,
        bytes memory userData
    ) private returns (uint256 bptAmountOut, uint256[] memory amountsIn) {
        JoinKind kind = userData.joinKind();

        if (kind == JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT) {
            return _joinExactTokensInForBPTOut(balances, scalingFactors, userData);
        } else {
            _revert(Errors.UNHANDLED_JOIN_KIND);
        }
    }

    function _joinExactTokensInForBPTOut(
        uint256[] memory balances,
        uint256[] memory scalingFactors,
        bytes memory userData
    ) private returns (uint256, uint256[] memory) {
        (uint256[] memory amountsIn, uint256 minBPTAmountOut) = userData.exactTokensInForBptOut();
        InputHelpers.ensureInputLengthMatch(_getTotalTokens(), amountsIn.length);

        _upscaleArray(amountsIn, scalingFactors);

        (uint256 currentAmp, ) = _getAmplificationParameter();

        _rateAdjustBalances(amountsIn);
        uint256 bptAmountOut = StableMath._calcBptOutGivenExactTokensIn(
            currentAmp,
            balances,
            amountsIn,
            totalSupply(),
            getSwapFeePercentage()
        );

        _require(bptAmountOut >= minBPTAmountOut, Errors.BPT_OUT_MIN_AMOUNT);

        return (bptAmountOut, amountsIn);
    }

    // Exit

    function _onExitPool(
        bytes32,
        address,
        address,
        uint256[] memory balances,
        uint256,
        uint256 protocolSwapFeePercentage,
        uint256[] memory scalingFactors,
        bytes memory userData
    )
        internal
        virtual
        override
        returns (
            uint256 bptAmountIn,
            uint256[] memory amountsOut,
            uint256[] memory dueProtocolFeeAmounts
        )
    {
        _rateAdjustBalances(balances);

        // Exits are not completely disabled while the contract is paused: proportional exits (exact BPT in for tokens
        // out) remain functional.

        if (_isNotPaused()) {
            // Due protocol swap fee amounts are computed by measuring the growth of the invariant between the previous
            // join or exit event and now - the invariant's growth is due exclusively to swap fees. This avoids
            // spending gas calculating fee amounts during each individual swap
            dueProtocolFeeAmounts = _getDueProtocolFeeAmounts(balances, protocolSwapFeePercentage);

            // Update current balances by subtracting the protocol fee amounts
            _mutateAmounts(balances, dueProtocolFeeAmounts, FixedPoint.sub);
        } else {
            // If the contract is paused, swap protocol fee amounts are not charged to avoid extra calculations and
            // reduce the potential for errors.
            dueProtocolFeeAmounts = new uint256[](_getTotalTokens());
        }

        (bptAmountIn, amountsOut) = _doExit(balances, scalingFactors, userData);

        // Update the invariant with the balances the Pool will have after the exit, in order to compute the
        // protocol swap fee amounts due in future joins and exits.
        _updateInvariantAfterExit(balances, amountsOut);

        _undoRateAdjustBalances(amountsOut);
        _undoRateAdjustBalances(dueProtocolFeeAmounts);

        return (bptAmountIn, amountsOut, dueProtocolFeeAmounts);
    }

    function _doExit(
        uint256[] memory balances,
        uint256[] memory scalingFactors,
        bytes memory userData
    ) private returns (uint256, uint256[] memory) {
        ExitKind kind = userData.exitKind();
        require(kind != ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, "Exit kind not supported!");

        if (kind == ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT) {
            return _exitExactBPTInForTokensOut(balances, userData);
        } else {
            // ExitKind.BPT_IN_FOR_EXACT_TOKENS_OUT
            return _exitBPTInForExactTokensOut(balances, scalingFactors, userData);
        }
    }

    function _exitExactBPTInForTokensOut(uint256[] memory balances, bytes memory userData)
        private
        returns (uint256, uint256[] memory)
    {
        // This exit function is the only one that is not disabled if the contract is paused: it remains unrestricted
        // in an attempt to provide users with a mechanism to retrieve their tokens in case of an emergency.
        // This particular exit function is the only one that remains available because it is the simplest one, and
        // therefore the one with the lowest likelihood of errors.

        uint256 bptAmountIn = userData.exactBptInForTokensOut();
        // Note that there is no minimum amountOut parameter: this is handled by `IVault.exitPool`.

        uint256[] memory amountsOut = StableMath._calcTokensOutGivenExactBptIn(balances, bptAmountIn, totalSupply());
        return (bptAmountIn, amountsOut);
    }

    function _exitBPTInForExactTokensOut(
        uint256[] memory balances,
        uint256[] memory scalingFactors,
        bytes memory userData
    ) private whenNotPaused beforeMaturity returns (uint256, uint256[] memory) {
        // This exit function is disabled if the contract is paused.

        (uint256[] memory amountsOut, uint256 maxBPTAmountIn) = userData.bptInForExactTokensOut();
        InputHelpers.ensureInputLengthMatch(amountsOut.length, _getTotalTokens());
        _upscaleArray(amountsOut, scalingFactors);

        _rateAdjustBalances(amountsOut);

        (uint256 currentAmp, ) = _getAmplificationParameter();
        uint256 bptAmountIn = StableMath._calcBptInGivenExactTokensOut(
            currentAmp,
            balances,
            amountsOut,
            totalSupply(),
            getSwapFeePercentage()
        );
        _require(bptAmountIn <= maxBPTAmountIn, Errors.BPT_IN_MAX_AMOUNT);

        return (bptAmountIn, amountsOut);
    }

    // Helpers

    /**
     * @dev Stores the last measured invariant, and the amplification parameter used to compute it.
     */
    function _updateLastInvariant(uint256 invariant, uint256 amplificationParameter) private {
        _lastInvariant = invariant;
        _lastInvariantAmp = amplificationParameter;
    }

    /**
     * @dev Returns the amount of protocol fees to pay, given the value of the last stored invariant and the current
     * balances.
     */
    function _getDueProtocolFeeAmounts(uint256[] memory balances, uint256 protocolSwapFeePercentage)
        private
        returns (uint256[] memory)
    {
        // Initialize with zeros
        uint256[] memory dueProtocolFeeAmounts = new uint256[](_getTotalTokens());

        // Early return if the protocol swap fee percentage is zero, saving gas.
        if (protocolSwapFeePercentage == 0) {
            return dueProtocolFeeAmounts;
        }

        // Instead of paying the protocol swap fee in all tokens proportionally, we will pay it in a single one. This
        // will reduce gas costs for single asset joins and exits, as at most only two Pool balances will change (the
        // token joined/exited, and the token in which fees will be paid).

        // The protocol fee is charged using the token with the highest balance in the pool.
        uint256 chosenTokenIndex = 0;
        uint256 maxBalance = balances[0];
        for (uint256 i = 1; i < _getTotalTokens(); ++i) {
            uint256 currentBalance = balances[i];
            if (currentBalance > maxBalance) {
                chosenTokenIndex = i;
                maxBalance = currentBalance;
            }
        }

        // Set the fee amount to pay in the selected token
        dueProtocolFeeAmounts[chosenTokenIndex] = StableMath._calcDueTokenProtocolSwapFeeAmount(
            _lastInvariantAmp,
            balances,
            _lastInvariant,
            chosenTokenIndex,
            protocolSwapFeePercentage
        );

        return dueProtocolFeeAmounts;
    }

    /**
     * @dev Computes and stores the value of the invariant after a join, which is required to compute due protocol fees
     * in the future.
     */
    function _updateInvariantAfterJoin(uint256[] memory balances, uint256[] memory amountsIn) private {
        _mutateAmounts(balances, amountsIn, FixedPoint.add);

        (uint256 currentAmp, ) = _getAmplificationParameter();
        // This invariant is used only to compute the final balance when calculating the protocol fees. These are
        // rounded down, so we round the invariant up.
        _updateLastInvariant(StableMath._calculateInvariant(currentAmp, balances, true), currentAmp);
    }

    /**
     * @dev Computes and stores the value of the invariant after an exit, which is required to compute due protocol fees
     * in the future.
     */
    function _updateInvariantAfterExit(uint256[] memory balances, uint256[] memory amountsOut) private {
        _mutateAmounts(balances, amountsOut, FixedPoint.sub);

        (uint256 currentAmp, ) = _getAmplificationParameter();
        // This invariant is used only to compute the final balance when calculating the protocol fees. These are
        // rounded down, so we round the invariant up.
        _updateLastInvariant(StableMath._calculateInvariant(currentAmp, balances, true), currentAmp);
    }

    /**
     * @dev Mutates `amounts` by applying `mutation` with each entry in `arguments`.
     *
     * Equivalent to `amounts = amounts.map(mutation)`.
     */
    function _mutateAmounts(
        uint256[] memory toMutate,
        uint256[] memory arguments,
        function(uint256, uint256) pure returns (uint256) mutation
    ) private view {
        for (uint256 i = 0; i < _getTotalTokens(); ++i) {
            toMutate[i] = mutation(toMutate[i], arguments[i]);
        }
    }

    // TODO: add docs
    function _rateAdjustBalances(uint256[] memory balances) private {
        uint256[] memory rates = new uint256[](2); // (balances.length) == 2
        rates[0] = _token0.getPricePerFullShare();
        rates[1] = _token1.getPricePerFullShare();

        _mutateAmounts(balances, rates, _mutateBalanceWithRate);
    }

    // TODO: add docs
    function _rateAdjustBalancesStored(uint256[] memory balances) private view {
        uint256[] memory rates = new uint256[](2); // (balances.length) == 2
        rates[0] = _token0.getPricePerFullShareStored();
        rates[1] = _token1.getPricePerFullShareStored();

        _mutateAmounts(balances, rates, _mutateBalanceWithRate);
    }

    function _mutateBalanceWithRate(uint256 balance, uint256 rate) private pure returns (uint256) {
        return (balance * rate) / _TEMPUS_SHARE_PRECISION;
    }

    // TODO: add docs
    function _undoRateAdjustBalances(uint256[] memory balances) private {
        uint256[] memory rates = new uint256[](2);
        rates[0] = _token0.getPricePerFullShare();
        rates[1] = _token1.getPricePerFullShare();

        _mutateAmounts(balances, rates, _unmutateBalanceWithRate);
    }

    function _unmutateBalanceWithRate(uint256 balance, uint256 rate) private pure returns (uint256) {
        return (balance * _TEMPUS_SHARE_PRECISION) / rate;
    }

    /**
     * @dev This function returns the appreciation of one BPT relative to the
     * underlying tokens. This starts at 1 when the pool is created and grows over time
     */
    function getRate() public view override returns (uint256) {
        (, uint256[] memory balances, ) = getVault().getPoolTokens(getPoolId());

        // When calculating the current BPT rate, we may not have paid the protocol fees, therefore
        // the invariant should be smaller than its current value. Then, we round down overall.
        (uint256 currentAmp, ) = _getAmplificationParameter();

        _upscaleArray(balances, _scalingFactors());

        _rateAdjustBalancesStored(balances);
        uint256 invariant = StableMath._calculateInvariant(currentAmp, balances, false);
        return invariant.divDown(totalSupply());
    }

    // Amplification

    /**
     * @dev Begins changing the amplification parameter to `rawEndValue` over time. The value will change linearly until
     * `endTime` is reached, when it will be `rawEndValue`.
     *
     * NOTE: Internally, the amplification parameter is represented using higher precision. The values returned by
     * `getAmplificationParameter` have to be corrected to account for this when comparing to `rawEndValue`.
     */
    function startAmplificationParameterUpdate(uint256 rawEndValue, uint256 endTime) external authenticate {
        _require(rawEndValue >= _MIN_AMP, Errors.MIN_AMP);
        _require(rawEndValue <= _MAX_AMP, Errors.MAX_AMP);

        uint256 duration = Math.sub(endTime, block.timestamp);
        _require(duration >= _MIN_UPDATE_TIME, Errors.AMP_END_TIME_TOO_CLOSE);

        (uint256 currentValue, bool isUpdating) = _getAmplificationParameter();
        _require(!isUpdating, Errors.AMP_ONGOING_UPDATE);

        uint256 endValue = Math.mul(rawEndValue, _AMP_PRECISION);

        // daily rate = (endValue / currentValue) / duration * 1 day
        // We perform all multiplications first to not reduce precision, and round the division up as we want to avoid
        // large rates. Note that these are regular integer multiplications and divisions, not fixed point.
        uint256 dailyRate = endValue > currentValue
            ? Math.divUp(Math.mul(1 days, endValue), Math.mul(currentValue, duration))
            : Math.divUp(Math.mul(1 days, currentValue), Math.mul(endValue, duration));
        _require(dailyRate <= _MAX_AMP_UPDATE_DAILY_RATE, Errors.AMP_RATE_TOO_HIGH);

        _setAmplificationData(currentValue, endValue, block.timestamp, endTime);
    }

    /**
     * @dev Stops the amplification parameter change process, keeping the current value.
     */
    function stopAmplificationParameterUpdate() external authenticate {
        (uint256 currentValue, bool isUpdating) = _getAmplificationParameter();
        _require(isUpdating, Errors.AMP_NO_ONGOING_UPDATE);

        _setAmplificationData(currentValue);
    }

    function _isOwnerOnlyAction(bytes32 actionId) internal view virtual override returns (bool) {
        return
            (actionId == getActionId(TempusAMM.startAmplificationParameterUpdate.selector)) ||
            (actionId == getActionId(TempusAMM.stopAmplificationParameterUpdate.selector)) ||
            super._isOwnerOnlyAction(actionId);
    }

    function getAmplificationParameter()
        external
        view
        returns (
            uint256 value,
            bool isUpdating,
            uint256 precision
        )
    {
        (value, isUpdating) = _getAmplificationParameter();
        precision = _AMP_PRECISION;
    }

    function _getAmplificationParameter() internal view returns (uint256 value, bool isUpdating) {
        (uint256 startValue, uint256 endValue, uint256 startTime, uint256 endTime) = _getAmplificationData();

        // Note that block.timestamp >= startTime, since startTime is set to the current time when an update starts

        if (block.timestamp < endTime) {
            isUpdating = true;

            // We can skip checked arithmetic as:
            //  - block.timestamp is always larger or equal to startTime
            //  - endTime is alawys larger than startTime
            //  - the value delta is bounded by the largest amplification paramater, which never causes the
            //    multiplication to overflow.
            // This also means that the following computation will never revert nor yield invalid results.
            if (endValue > startValue) {
                value = startValue + ((endValue - startValue) * (block.timestamp - startTime)) / (endTime - startTime);
            } else {
                value = startValue - ((startValue - endValue) * (block.timestamp - startTime)) / (endTime - startTime);
            }
        } else {
            isUpdating = false;
            value = endValue;
        }
    }

    function _getMaxTokens() internal pure override returns (uint256) {
        return _MAX_STABLE_TOKENS;
    }

    function _getTotalTokens() internal view virtual override returns (uint256) {
        return _totalTokens;
    }

    function _scalingFactor(IERC20 token) internal view virtual override returns (uint256 scalingFactor) {
        // prettier-ignore
        if (_isToken0(token)) { return _scalingFactor0; }
        else if (_isToken1(token)) { return _scalingFactor1; }
        else {
            _revert(Errors.INVALID_TOKEN);
        }
    }

    function _scalingFactors() internal view virtual override returns (uint256[] memory) {
        uint256 totalTokens = _getTotalTokens();
        uint256[] memory scalingFactors = new uint256[](totalTokens);

        // prettier-ignore
        {
            if (totalTokens > 0) { scalingFactors[0] = _scalingFactor0; } else { return scalingFactors; }
            if (totalTokens > 1) { scalingFactors[1] = _scalingFactor1; } else { return scalingFactors; }
        }

        return scalingFactors;
    }

    function _setAmplificationData(uint256 value) private {
        _setAmplificationData(value, value, block.timestamp, block.timestamp);

        emit AmpUpdateStopped(value);
    }

    function _setAmplificationData(
        uint256 startValue,
        uint256 endValue,
        uint256 startTime,
        uint256 endTime
    ) private {
        _packedAmplificationData =
            WordCodec.encodeUint(uint64(startValue), 0) |
            WordCodec.encodeUint(uint64(endValue), 64) |
            WordCodec.encodeUint(uint64(startTime), 64 * 2) |
            WordCodec.encodeUint(uint64(endTime), 64 * 3);

        emit AmpUpdateStarted(startValue, endValue, startTime, endTime);
    }

    function _getAmplificationData()
        private
        view
        returns (
            uint256 startValue,
            uint256 endValue,
            uint256 startTime,
            uint256 endTime
        )
    {
        startValue = _packedAmplificationData.decodeUint64(0);
        endValue = _packedAmplificationData.decodeUint64(64);
        startTime = _packedAmplificationData.decodeUint64(64 * 2);
        endTime = _packedAmplificationData.decodeUint64(64 * 3);
    }

    function _isToken0(IERC20 token) internal view returns (bool) {
        return address(token) == address(_token0);
    }

    function _isToken1(IERC20 token) internal view returns (bool) {
        return address(token) == address(_token1);
    }

    function _mapTempusSharesToIERC20(ITempusPool pool) private view returns (IERC20[] memory) {
        IERC20[] memory tokens = new IERC20[](2);
        IPoolShare yieldShare = pool.yieldShare();
        IPoolShare principalShare = pool.principalShare();
        (tokens[0], tokens[1]) = (yieldShare < principalShare)
            ? (IERC20(address(yieldShare)), IERC20(address(principalShare)))
            : (IERC20(address(principalShare)), IERC20(address(yieldShare)));
        return tokens;
    }
}
