pragma solidity 0.5.10;

import "./StakingAuRaBase.sol";
import "../interfaces/IBlockRewardAuRaCoins.sol";


contract Sacrifice {
    constructor(address payable _recipient) public payable {
        selfdestruct(_recipient);
    }
}


/// @dev Implements staking and withdrawal logic.
contract StakingAuRaCoins is StakingAuRaBase {

    // ================================================ Events ========================================================

    /// @dev Emitted by the `claimReward` function to signal the staker withdrew the specified
    /// amount of native coins from the specified pool for the specified staking epoch.
    /// @param fromPoolStakingAddress A staking address of the pool from which the `staker` withdrew the amount.
    /// @param staker The address of the staker that withdrew the amount.
    /// @param stakingEpoch The serial number of the staking epoch for which the claim was made.
    /// @param nativeCoinsAmount The withdrawal amount of native coins.
    /// @param fromPoolId An id of the pool from which the `staker` withdrew the amount.
    event ClaimedReward(
        address indexed fromPoolStakingAddress,
        address indexed staker,
        uint256 indexed stakingEpoch,
        uint256 nativeCoinsAmount,
        uint256 fromPoolId
    );

    // =============================================== Setters ========================================================

    /// @dev Withdraws a reward from the specified pool for the specified staking epochs
    /// to the staker address (msg.sender).
    /// @param _stakingEpochs The list of staking epochs in ascending order.
    /// If the list is empty, it is taken with `BlockRewardAuRa.epochsPoolGotRewardFor` getter.
    /// @param _poolStakingAddress The staking address of the pool from which the reward needs to be withdrawn.
    function claimReward(
        uint256[] memory _stakingEpochs,
        address _poolStakingAddress
    ) public gasPriceIsValid onlyInitialized {
        address payable staker = msg.sender;
        uint256 poolId = validatorSetContract.idByStakingAddress(_poolStakingAddress);

        require(_poolStakingAddress != address(0));
        require(staker != address(0));
        require(poolId != 0);

        address delegatorOrZero = (staker != _poolStakingAddress) ? staker : address(0);
        uint256 firstEpoch;
        uint256 lastEpoch;

        if (_poolStakingAddress != staker) { // this is a delegator
            firstEpoch = stakeFirstEpoch[poolId][staker];
            require(firstEpoch != 0);
            lastEpoch = stakeLastEpoch[poolId][staker];
        }

        IBlockRewardAuRaCoins blockRewardContract = IBlockRewardAuRaCoins(validatorSetContract.blockRewardContract());
        uint256 rewardSum = 0;
        uint256 delegatorStake = 0;

        if (_stakingEpochs.length == 0) {
            _stakingEpochs = IBlockRewardAuRa(address(blockRewardContract)).epochsPoolGotRewardFor(poolId);
        }

        for (uint256 i = 0; i < _stakingEpochs.length; i++) {
            uint256 epoch = _stakingEpochs[i];

            require(i == 0 || epoch > _stakingEpochs[i - 1]);
            require(epoch < stakingEpoch);

            if (rewardWasTaken[poolId][delegatorOrZero][epoch]) continue;
            
            uint256 reward;

            if (_poolStakingAddress != staker) { // this is a delegator
                if (epoch < firstEpoch) {
                    // If the delegator staked for the first time before
                    // the `epoch`, skip this staking epoch
                    continue;
                }

                if (lastEpoch <= epoch && lastEpoch != 0) {
                    // If the delegator withdrew all their stake before the `epoch`,
                    // don't check this and following epochs since it makes no sense
                    break;
                }

                delegatorStake = _getDelegatorStake(epoch, firstEpoch, delegatorStake, poolId, staker);
                firstEpoch = epoch + 1;

                reward = blockRewardContract.getDelegatorReward(delegatorStake, epoch, poolId);
            } else { // this is a validator
                reward = blockRewardContract.getValidatorReward(epoch, poolId);
            }

            rewardSum = rewardSum.add(reward);

            rewardWasTaken[poolId][delegatorOrZero][epoch] = true;

            emit ClaimedReward(_poolStakingAddress, staker, epoch, reward, poolId);
        }

        blockRewardContract.transferReward(rewardSum, staker);
    }

    // =============================================== Getters ========================================================

    /// @dev Returns reward amount in native coins for the specified pool, the specified staking epochs,
    /// and the specified staker address (delegator or validator).
    /// @param _stakingEpochs The list of staking epochs in ascending order.
    /// If the list is empty, it is taken with `BlockRewardAuRa.epochsPoolGotRewardFor` getter.
    /// @param _poolStakingAddress The staking address of the pool for which the amounts need to be returned.
    /// @param _staker The staker address (validator's staking address or delegator's address).
    function getRewardAmount(
        uint256[] memory _stakingEpochs,
        address _poolStakingAddress,
        address _staker
    ) public view returns(uint256 rewardSum) {
        uint256 poolId = validatorSetContract.idByStakingAddress(_poolStakingAddress);

        require(_poolStakingAddress != address(0));
        require(_staker != address(0));
        require(poolId != 0);

        address delegatorOrZero = (_staker != _poolStakingAddress) ? _staker : address(0);
        uint256 firstEpoch;
        uint256 lastEpoch;

        if (_poolStakingAddress != _staker) { // this is a delegator
            firstEpoch = stakeFirstEpoch[poolId][_staker];
            require(firstEpoch != 0);
            lastEpoch = stakeLastEpoch[poolId][_staker];
        }

        IBlockRewardAuRaCoins blockRewardContract = IBlockRewardAuRaCoins(validatorSetContract.blockRewardContract());
        uint256 delegatorStake = 0;
        rewardSum = 0;

        if (_stakingEpochs.length == 0) {
            _stakingEpochs = IBlockRewardAuRa(address(blockRewardContract)).epochsPoolGotRewardFor(poolId);
        }

        for (uint256 i = 0; i < _stakingEpochs.length; i++) {
            uint256 epoch = _stakingEpochs[i];

            require(i == 0 || epoch > _stakingEpochs[i - 1]);
            require(epoch < stakingEpoch);

            if (rewardWasTaken[poolId][delegatorOrZero][epoch]) continue;

            uint256 reward;

            if (_poolStakingAddress != _staker) { // this is a delegator
                if (epoch < firstEpoch) continue;
                if (lastEpoch <= epoch && lastEpoch != 0) break;

                delegatorStake = _getDelegatorStake(epoch, firstEpoch, delegatorStake, poolId, _staker);
                firstEpoch = epoch + 1;

                reward = blockRewardContract.getDelegatorReward(delegatorStake, epoch, poolId);
            } else { // this is a validator
                reward = blockRewardContract.getValidatorReward(epoch, poolId);
            }

            rewardSum += reward;
        }
    }

    // ============================================== Internal ========================================================

    /// @dev Sends coins from this contract to the specified address.
    /// @param _to The target address to send amount to.
    /// @param _amount The amount to send.
    function _sendWithdrawnStakeAmount(address payable _to, uint256 _amount) internal gasPriceIsValid onlyInitialized {
        if (!_to.send(_amount)) {
            // We use the `Sacrifice` trick to be sure the coins can be 100% sent to the receiver.
            // Otherwise, if the receiver is a contract which has a revert in its fallback function,
            // the sending will fail.
            (new Sacrifice).value(_amount)(_to);
        }
        lastChangeBlock = _getCurrentBlockNumber();
    }

    /// @dev The internal function used by the `stake` and `addPool` functions.
    /// See the `stake` public function for more details.
    /// @param _toPoolStakingAddress The staking address of the pool where the coins should be staked.
    /// @param _amount The amount of coins to be staked.
    function _stake(address _toPoolStakingAddress, uint256 _amount) internal {
        address staker = msg.sender;
        _amount = msg.value;
        _stake(_toPoolStakingAddress, staker, _amount);
    }

    /// @dev Returns the balance of this contract in staking coins.
    function _thisBalance() internal view returns(uint256) {
        return address(this).balance;
    }

}
