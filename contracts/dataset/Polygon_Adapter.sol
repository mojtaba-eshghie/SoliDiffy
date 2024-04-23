// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../interfaces/AdapterInterface.sol";
import "../interfaces/WETH9.sol";

import "@eth-optimism/contracts/libraries/bridge/CrossDomainEnabled.sol";
import "@eth-optimism/contracts/L1/messaging/IL1StandardBridge.sol";
import "../Lockable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IRootChainManager {
    function depositEtherFor(address user) external payable;

    function depositFor(
        address user,
        address rootToken,
        bytes calldata depositData
    ) external;
}

interface IFxStateSender {
    function sendMessageToChild(address _receiver, bytes calldata _data) external;
}

/**
 * @notice Sends cross chain messages Polygon L2 network.
 */
contract Polygon_Adapter is AdapterInterface {
    using SafeERC20 for IERC20;
    IRootChainManager public immutable rootChainManager;
    IFxStateSender public immutable fxStateSender;
    WETH9 public immutable l1Weth;

    /**
     * @notice Constructs new Adapter.
     * @param _rootChainManager RootChainManager Polygon system helper contract.
     * @param _fxStateSender FxStateSender Polygon system helper contract.
     * @param _l1Weth WETH address on L1.
     */
    constructor(
        IRootChainManager _rootChainManager,
        IFxStateSender _fxStateSender,
        WETH9 _l1Weth
    ) {
        rootChainManager = _rootChainManager;
        fxStateSender = _fxStateSender;
        l1Weth = _l1Weth;
    }

    /**
     * @notice Send cross-chain message to target on Polygon.
     * @param target Contract on Polygon that will receive message.
     * @param message Data to send to target.
     */

    function relayMessage(address target, bytes memory message) external payable override {
        fxStateSender.sendMessageToChild(target, message);
        emit MessageRelayed(target, message);
    }

    /**
     * @notice Bridge tokens to Polygon.
     * @param l1Token L1 token to deposit.
     * @param l2Token L2 token to receive.
     * @param amount Amount of L1 tokens to deposit and L2 tokens to receive.
     * @param to Bridge recipient.
     */
    function relayTokens(
        address l1Token,
        address l2Token,
        uint256 amount,
        address to
    ) external payable override {
        // If the l1Token is weth then unwrap it to ETH then send the ETH to the standard bridge.
        if (l1Token == address(l1Weth)) {
            l1Weth.withdraw(amount);
            rootChainManager.depositEtherFor{ value: amount }(to);
        } else {
            IERC20(l1Token).safeIncreaseAllowance(address(rootChainManager), amount);
            rootChainManager.depositFor(to, l1Token, abi.encode(amount));
        }
        emit TokensRelayed(l1Token, l2Token, amount, to);
    }
}
