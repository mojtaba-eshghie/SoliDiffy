// SPDX-License-Identifier: BUSL-1.1
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

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";

import "../../apis/pancake/IPancakeRouter02.sol";
import "@pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakeFactory.sol";

import "../../interfaces/IStrategy.sol";
import "../../interfaces/IWorker02.sol";
import "../../interfaces/IWNativeRelayer.sol";

import "../../../utils/SafeToken.sol";

contract PancakeswapV2RestrictedSingleAssetStrategyPartialCloseMinimizeTrading is
  OwnableUpgradeSafe,
  ReentrancyGuardUpgradeSafe,
  IStrategy
{
  using SafeToken for address;
  using SafeMath for uint256;

  IPancakeFactory public factory;
  IPancakeRouter02 public router;
  address public wbnb;
  mapping(address => bool) public okWorkers;
  IWNativeRelayer public wNativeRelayer;

  event PancakeswapV2RestrictedSingleAssetStrategyPartialCloseMinimizeTradingEvent(
    address indexed baseToken,
    address indexed farmToken,
    uint256 amounToLiquidate,
    uint256 amountToRepayDebt
  );

  /// @notice require that only allowed workers are able to do the rest of the method call
  modifier onlyWhitelistedWorkers() {
    require(
      okWorkers[msg.sender],
      "PancakeswapV2RestrictedSingleAssetStrategyPartialCloseMinimizeTrading::onlyWhitelistedWorkers:: bad worker"
    );
    _;
  }

  /// @dev Create a new add Token only strategy instance.
  /// @param _router The Pancakeswap router smart contract.
  function initialize(IPancakeRouter02 _router, IWNativeRelayer _wNativeRelayer) external initializer {
    OwnableUpgradeSafe.__Ownable_init();
    ReentrancyGuardUpgradeSafe.__ReentrancyGuard_init();
    factory = IPancakeFactory(_router.factory());
    router = _router;
    wbnb = _router.WETH();
    wNativeRelayer = _wNativeRelayer;
  }

  /// @dev Execute worker strategy. take farmingToken, return farmingToken + basetoken that is enough to repay the debt
  /// @param data Extra calldata information passed along to this strategy.
  function execute(
    address user,
    uint256 debt,
    bytes calldata data
  ) external override onlyWhitelistedWorkers nonReentrant {
    // 1. Decode variables from extra data & load required variables.
    // - maxFarmingTokenToLiquidate -> maximum farmingToken amount that user want to liquidate.
    // - maxDebtRepayment -> maximum BTOKEN amount that user want to repaid debt.
    // - minFarmingTokenAmount -> minimum farmingToken that user want to receive.
    (uint256 maxFarmingTokenToLiquidate, uint256 maxDebtRepayment, uint256 minFarmingTokenAmount) =
      abi.decode(data, (uint256, uint256, uint256));
    IWorker02 worker = IWorker02(msg.sender);
    address baseToken = worker.baseToken();
    address farmingToken = worker.farmingToken();
    uint256 farmingTokenToLiquidate = Math.min(farmingToken.myBalance(), maxFarmingTokenToLiquidate);
    uint256 lessDebt = Math.min(debt, maxDebtRepayment);
    // 2. Approve router to do their stuffs.
    farmingToken.safeApprove(address(router), uint256(-1));
    // 3. check farmingToken amount to liquidate more than equal farmingToken balance.
    uint256 farmingTokenToRepaidDebt = 0;
    if (lessDebt > 0) {
      // 4. Swap from farming token -> base token according to worker's path.
      // Router will be reverted with 'PancakeRouter: EXCESSIVE_INPUT_AMOUNT' if not enough farmingToken
      farmingTokenToRepaidDebt = router.swapTokensForExactTokens(
        lessDebt,
        farmingTokenToLiquidate,
        worker.getReversedPath(),
        address(this),
        now
      )[0];
    }
    uint256 farmingTokenBalanceToBeSentToTheUser = farmingTokenToLiquidate.sub(farmingTokenToRepaidDebt);
    // 5. Return baseToken back to the original caller in order to repay the debt.
    baseToken.safeTransfer(msg.sender, baseToken.myBalance());
    // 6. Return the partial farmingTokens back to the user.
    require(
      farmingTokenBalanceToBeSentToTheUser >= minFarmingTokenAmount,
      "PancakeswapV2RestrictedSingleAssetStrategyPartialCloseMinimizeTrading::execute:: insufficient farmingToken amount received"
    );
    if (farmingTokenBalanceToBeSentToTheUser > 0) {
      if (farmingToken == address(wbnb)) {
        SafeToken.safeTransfer(farmingToken, address(wNativeRelayer), farmingTokenBalanceToBeSentToTheUser);
        wNativeRelayer.withdraw(farmingTokenBalanceToBeSentToTheUser);
        SafeToken.safeTransferETH(user, farmingTokenBalanceToBeSentToTheUser);
      } else {
        SafeToken.safeTransfer(farmingToken, user, farmingTokenBalanceToBeSentToTheUser);
      }
    }
    // 7. Return farmingToken back to the original caller.
    farmingToken.safeTransfer(msg.sender, farmingToken.myBalance());
    // 8. Reset approval for safety reason.
    farmingToken.safeApprove(address(router), 0);
    emit PancakeswapV2RestrictedSingleAssetStrategyPartialCloseMinimizeTradingEvent(
      baseToken,
      farmingToken,
      farmingTokenToLiquidate,
      lessDebt
    );
  }

  function setWorkersOk(address[] calldata workers, bool isOk) external onlyOwner {
    for (uint256 idx = 0; idx < workers.length; idx++) {
      okWorkers[workers[idx]] = isOk;
    }
  }

  receive() external payable {}
}
