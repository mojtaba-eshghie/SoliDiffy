// SPDX-License-Identifier: MIT
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakeFactory.sol";
import "@pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakePair.sol";

import "../interfaces/IWorker02.sol";
import "../apis/pancake/IPancakeRouter02.sol";
import "../interfaces/IWorkerConfig.sol";
import "../interfaces/IPriceOracle.sol";
import "../../utils/SafeToken.sol";

contract SingleAssetWorkerConfig is OwnableUpgradeSafe, IWorkerConfig {
  /// @notice Using libraries
  using SafeToken for address;
  using SafeMath for uint256;

  /// @notice Events
  event SetOracle(address indexed caller, address oracle);
  event SetConfig(
    address indexed caller,
    address indexed worker,
    bool acceptDebt,
    uint64 workFactor,
    uint64 killFactor,
    uint64 maxPriceDiff
  );
  event SetGovernor(address indexed caller, address indexed governor);

  /// @notice state variables
  struct Config {
    bool acceptDebt;
    uint64 workFactor;
    uint64 killFactor;
    uint64 maxPriceDiff;
  }

  PriceOracle public oracle;
  IPancakeFactory public factory;
  address public wNative;
  mapping(address => Config) public workers;
  address public governor;

  function initialize(PriceOracle _oracle, IPancakeRouter02 _router) external initializer {
    OwnableUpgradeSafe.__Ownable_init();
    oracle = _oracle;
    factory = IPancakeFactory(_router.factory());
    wNative = _router.WETH();
  }

  /// @dev Check if the msg.sender is the governor.
  modifier onlyGovernor() {
    require(_msgSender() == governor, "SingleAssetWorkerConfig::onlyGovernor:: msg.sender not governor");
    _;
  }

  /// @dev Set oracle address. Must be called by owner.
  function setOracle(PriceOracle _oracle) external onlyOwner {
    oracle = _oracle;
    emit SetOracle(_msgSender(), address(oracle));
  }

  /// @dev Set worker configurations. Must be called by owner.
  function setConfigs(address[] calldata addrs, Config[] calldata configs) external onlyOwner {
    uint256 len = addrs.length;
    require(configs.length == len, "SingleAssetWorkerConfig::setConfigs:: bad len");
    for (uint256 idx = 0; idx < len; idx++) {
      workers[addrs[idx]] = Config({
        acceptDebt: configs[idx].acceptDebt,
        workFactor: configs[idx].workFactor,
        killFactor: configs[idx].killFactor,
        maxPriceDiff: configs[idx].maxPriceDiff
      });
      emit SetConfig(
        _msgSender(),
        addrs[idx],
        workers[addrs[idx]].acceptDebt,
        workers[addrs[idx]].workFactor,
        workers[addrs[idx]].killFactor,
        workers[addrs[idx]].maxPriceDiff
      );
    }
  }

  function isReserveConsistent(address _worker) public view override returns (bool) {
    IWorker02 worker = IWorker02(_worker);
    address[] memory path = worker.getPath();
    IPancakePair currentLP;
    for (uint256 i = 1; i < path.length; i++) {
      // 1. Get the position's LP balance and LP total supply.
      currentLP = IPancakePair(factory.getPair(path[i - 1], path[i]));
      address token0 = currentLP.token0();
      address token1 = currentLP.token1();
      // 2. Check that reserves and balances are consistent (within 1%)
      (uint256 r0, uint256 r1, ) = currentLP.getReserves();
      uint256 t0bal = token0.balanceOf(address(currentLP));
      uint256 t1bal = token1.balanceOf(address(currentLP));
      _isReserveConsistent(r0, r1, t0bal, t1bal);
    }
    return true;
  }

  function _isReserveConsistent(
    uint256 r0,
    uint256 r1,
    uint256 t0bal,
    uint256 t1bal
  ) internal pure {
    require(t0bal.mul(100) <= r0.mul(101), "SingleAssetWorkerConfig::isReserveConsistent:: bad t0 balance");
    require(t1bal.mul(100) <= r1.mul(101), "SingleAssetWorkerConfig::isReserveConsistent:: bad t1 balance");
  }

  /// @dev Return whether the given worker is stable, presumably not under manipulation.
  function isStable(address _worker) public view override returns (bool) {
    IWorker02 worker = IWorker02(_worker);
    address[] memory path = worker.getPath();
    // @notice loop over the path for validating the price of each pair
    IPancakePair currentLP;
    uint256 maxPriceDiff = workers[_worker].maxPriceDiff;
    for (uint256 i = 1; i < path.length; i++) {
      // 1. Get the position's LP balance and LP total supply.
      currentLP = IPancakePair(factory.getPair(path[i - 1], path[i]));
      address token0 = currentLP.token0();
      address token1 = currentLP.token1();
      // 2. Check that reserves and balances are consistent (within 1%)
      (uint256 r0, uint256 r1, ) = currentLP.getReserves();
      uint256 t0bal = token0.balanceOf(address(currentLP));
      uint256 t1bal = token1.balanceOf(address(currentLP));
      _isReserveConsistent(r0, r1, t0bal, t1bal);
      // 3. Check that price is in the acceptable range
      (uint256 price, uint256 lastUpdate) = oracle.getPrice(token0, token1);
      require(lastUpdate >= now - 1 days, "SingleAssetWorkerConfig::isStable:: price too stale");
      uint256 spotPrice = r1.mul(1e18).div(r0);
      require(spotPrice.mul(10000) <= price.mul(maxPriceDiff), "SingleAssetWorkerConfig::isStable:: price too high");
      require(spotPrice.mul(maxPriceDiff) >= price.mul(10000), "SingleAssetWorkerConfig::isStable:: price too low");
    }
    return true;
  }

  /// @dev Return whether the given worker accepts more debt.
  function acceptDebt(address worker) external view override returns (bool) {
    require(isStable(worker), "SingleAssetWorkerConfig::acceptDebt:: !stable");
    return workers[worker].acceptDebt;
  }

  /// @dev Return the work factor for the worker + BaseToken debt, using 1e4 as denom.
  function workFactor(
    address worker,
    uint256 /* debt */
  ) external view override returns (uint256) {
    require(isStable(worker), "SingleAssetWorkerConfig::workFactor:: !stable");
    return uint256(workers[worker].workFactor);
  }

  /// @dev Return the kill factor for the worker + BaseToken debt, using 1e4 as denom.
  function killFactor(
    address worker,
    uint256 /* debt */
  ) external view override returns (uint256) {
    require(isStable(worker), "SingleAssetWorkerConfig::killFactor:: !stable");
    return uint256(workers[worker].killFactor);
  }

  /// @dev Return the kill factor for the worker + BaseToken debt, using 1e4 as denom.
  function rawKillFactor(
    address worker,
    uint256 /* debt */
  ) external view override returns (uint256) {
    return uint256(workers[worker].killFactor);
  }

  /// @dev Set governor address. OnlyOwner can set governor.
  function setGovernor(address newGovernor) external onlyOwner {
    governor = newGovernor;
    emit SetGovernor(_msgSender(), governor);
  }

  /// @dev EMERGENCY ONLY. Disable accept new position without going through Timelock in case of emergency.
  function emergencySetAcceptDebt(address[] calldata addrs, bool isAcceptDebt) external onlyGovernor {
    uint256 len = addrs.length;
    for (uint256 idx = 0; idx < len; idx++) {
      workers[addrs[idx]].acceptDebt = isAcceptDebt;
      emit SetConfig(
        _msgSender(),
        addrs[idx],
        workers[addrs[idx]].acceptDebt,
        workers[addrs[idx]].workFactor,
        workers[addrs[idx]].killFactor,
        workers[addrs[idx]].maxPriceDiff
      );
    }
  }
}
