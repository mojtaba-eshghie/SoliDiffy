pragma solidity 0.6.6;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

import "@pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakeFactory.sol";

import "../../interfaces/IWETH.sol";
import "./PancakeLibraryV2.sol";
import "../pancake/IPancakeRouter02.sol";
import "../../../utils/SafeToken.sol";

contract PancakeRouterV2 is IPancakeRouter02 {
  using SafeMath for uint256;

  address public immutable override factory;
  address public immutable override WETH;

  modifier ensure(uint256 deadline) {
    require(deadline >= block.timestamp, "PancakeRouter: EXPIRED");
    _;
  }

  constructor(address _factory, address _WETH) public {
    factory = _factory;
    WETH = _WETH;
  }

  receive() external payable {
    assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
  }

  // **** ADD LIQUIDITY ****
  function _addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin
  ) internal virtual returns (uint256 amountA, uint256 amountB) {
    // create the pair if it doesn't exist yet
    if (IPancakeFactory(factory).getPair(tokenA, tokenB) == address(0)) {
      IPancakeFactory(factory).createPair(tokenA, tokenB);
    }
    (uint256 reserveA, uint256 reserveB) = PancakeLibraryV2.getReserves(factory, tokenA, tokenB);
    if (reserveA == 0 && reserveB == 0) {
      (amountA, amountB) = (amountADesired, amountBDesired);
    } else {
      uint256 amountBOptimal = PancakeLibraryV2.quote(amountADesired, reserveA, reserveB);
      if (amountBOptimal <= amountBDesired) {
        require(amountBOptimal >= amountBMin, "PancakeRouter: INSUFFICIENT_B_AMOUNT");
        (amountA, amountB) = (amountADesired, amountBOptimal);
      } else {
        uint256 amountAOptimal = PancakeLibraryV2.quote(amountBDesired, reserveB, reserveA);
        assert(amountAOptimal <= amountADesired);
        require(amountAOptimal >= amountAMin, "PancakeRouter: INSUFFICIENT_A_AMOUNT");
        (amountA, amountB) = (amountAOptimal, amountBDesired);
      }
    }
  }

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    virtual
    override
    ensure(deadline)
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    )
  {
    (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
    address pair = PancakeLibraryV2.pairFor(factory, tokenA, tokenB);
    SafeToken.safeTransferFrom(tokenA, msg.sender, pair, amountA);
    SafeToken.safeTransferFrom(tokenB, msg.sender, pair, amountB);
    liquidity = IPancakePair(pair).mint(to);
  }

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    virtual
    override
    ensure(deadline)
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    )
  {
    (amountToken, amountETH) = _addLiquidity(token, WETH, amountTokenDesired, msg.value, amountTokenMin, amountETHMin);
    address pair = PancakeLibraryV2.pairFor(factory, token, WETH);
    SafeToken.safeTransferFrom(token, msg.sender, pair, amountToken);
    IWETH(WETH).deposit{ value: amountETH }();
    assert(IWETH(WETH).transfer(pair, amountETH));
    liquidity = IPancakePair(pair).mint(to);
    // refund dust eth, if any
    if (msg.value > amountETH) SafeToken.safeTransferETH(msg.sender, msg.value - amountETH);
  }

  // **** REMOVE LIQUIDITY ****
  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) public virtual override ensure(deadline) returns (uint256 amountA, uint256 amountB) {
    address pair = PancakeLibraryV2.pairFor(factory, tokenA, tokenB);
    IPancakePair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
    (uint256 amount0, uint256 amount1) = IPancakePair(pair).burn(to);
    (address token0, ) = PancakeLibraryV2.sortTokens(tokenA, tokenB);
    (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
    require(amountA >= amountAMin, "PancakeRouter: INSUFFICIENT_A_AMOUNT");
    require(amountB >= amountBMin, "PancakeRouter: INSUFFICIENT_B_AMOUNT");
  }

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) public virtual override ensure(deadline) returns (uint256 amountToken, uint256 amountETH) {
    (amountToken, amountETH) = removeLiquidity(
      token,
      WETH,
      liquidity,
      amountTokenMin,
      amountETHMin,
      address(this),
      deadline
    );
    SafeToken.safeTransfer(token, to, amountToken);
    IWETH(WETH).withdraw(amountETH);
    SafeToken.safeTransferETH(to, amountETH);
  }

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external virtual override returns (uint256 amountA, uint256 amountB) {
    address pair = PancakeLibraryV2.pairFor(factory, tokenA, tokenB);
    uint256 value = approveMax ? uint256(-1) : liquidity;
    IPancakePair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
    (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
  }

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external virtual override returns (uint256 amountToken, uint256 amountETH) {
    address pair = PancakeLibraryV2.pairFor(factory, token, WETH);
    uint256 value = approveMax ? uint256(-1) : liquidity;
    IPancakePair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
    (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
  }

  // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) public virtual override ensure(deadline) returns (uint256 amountETH) {
    (, amountETH) = removeLiquidity(token, WETH, liquidity, amountTokenMin, amountETHMin, address(this), deadline);
    SafeToken.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
    IWETH(WETH).withdraw(amountETH);
    SafeToken.safeTransferETH(to, amountETH);
  }

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external virtual override returns (uint256 amountETH) {
    address pair = PancakeLibraryV2.pairFor(factory, token, WETH);
    uint256 value = approveMax ? uint256(-1) : liquidity;
    IPancakePair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
    amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
      token,
      liquidity,
      amountTokenMin,
      amountETHMin,
      to,
      deadline
    );
  }

  // **** SWAP ****
  // requires the initial amount to have already been sent to the first pair
  function _swap(
    uint256[] memory amounts,
    address[] memory path,
    address _to
  ) internal virtual {
    for (uint256 i; i < path.length - 1; i++) {
      (address input, address output) = (path[i], path[i + 1]);
      (address token0, ) = PancakeLibraryV2.sortTokens(input, output);
      uint256 amountOut = amounts[i + 1];
      (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
      address to = i < path.length - 2 ? PancakeLibraryV2.pairFor(factory, output, path[i + 2]) : _to;
      IPancakePair(PancakeLibraryV2.pairFor(factory, input, output)).swap(amount0Out, amount1Out, to, new bytes(0));
    }
  }

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
    amounts = PancakeLibraryV2.getAmountsOut(factory, amountIn, path);
    require(amounts[amounts.length - 1] >= amountOutMin, "PancakeRouter: INSUFFICIENT_OUTPUT_AMOUNT");
    SafeToken.safeTransferFrom(path[0], msg.sender, PancakeLibraryV2.pairFor(factory, path[0], path[1]), amounts[0]);
    _swap(amounts, path, to);
  }

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
    amounts = PancakeLibraryV2.getAmountsIn(factory, amountOut, path);
    require(amounts[0] <= amountInMax, "PancakeRouter: EXCESSIVE_INPUT_AMOUNT");
    SafeToken.safeTransferFrom(path[0], msg.sender, PancakeLibraryV2.pairFor(factory, path[0], path[1]), amounts[0]);
    _swap(amounts, path, to);
  }

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable virtual override ensure(deadline) returns (uint256[] memory amounts) {
    require(path[0] == WETH, "PancakeRouter: INVALID_PATH");
    amounts = PancakeLibraryV2.getAmountsOut(factory, msg.value, path);
    require(amounts[amounts.length - 1] >= amountOutMin, "PancakeRouter: INSUFFICIENT_OUTPUT_AMOUNT");
    IWETH(WETH).deposit{ value: amounts[0] }();
    assert(IWETH(WETH).transfer(PancakeLibraryV2.pairFor(factory, path[0], path[1]), amounts[0]));
    _swap(amounts, path, to);
  }

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
    require(path[path.length - 1] == WETH, "PancakeRouter: INVALID_PATH");
    amounts = PancakeLibraryV2.getAmountsIn(factory, amountOut, path);
    require(amounts[0] <= amountInMax, "PancakeRouter: EXCESSIVE_INPUT_AMOUNT");
    SafeToken.safeTransferFrom(path[0], msg.sender, PancakeLibraryV2.pairFor(factory, path[0], path[1]), amounts[0]);
    _swap(amounts, path, address(this));
    IWETH(WETH).withdraw(amounts[amounts.length - 1]);
    SafeToken.safeTransferETH(to, amounts[amounts.length - 1]);
  }

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
    require(path[path.length - 1] == WETH, "PancakeRouter: INVALID_PATH");
    amounts = PancakeLibraryV2.getAmountsOut(factory, amountIn, path);
    require(amounts[amounts.length - 1] >= amountOutMin, "PancakeRouter: INSUFFICIENT_OUTPUT_AMOUNT");
    SafeToken.safeTransferFrom(path[0], msg.sender, PancakeLibraryV2.pairFor(factory, path[0], path[1]), amounts[0]);
    _swap(amounts, path, address(this));
    IWETH(WETH).withdraw(amounts[amounts.length - 1]);
    SafeToken.safeTransferETH(to, amounts[amounts.length - 1]);
  }

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable virtual override ensure(deadline) returns (uint256[] memory amounts) {
    require(path[0] == WETH, "PancakeRouter: INVALID_PATH");
    amounts = PancakeLibraryV2.getAmountsIn(factory, amountOut, path);
    require(amounts[0] <= msg.value, "PancakeRouter: EXCESSIVE_INPUT_AMOUNT");
    IWETH(WETH).deposit{ value: amounts[0] }();
    assert(IWETH(WETH).transfer(PancakeLibraryV2.pairFor(factory, path[0], path[1]), amounts[0]));
    _swap(amounts, path, to);
    // refund dust eth, if any
    if (msg.value > amounts[0]) SafeToken.safeTransferETH(msg.sender, msg.value - amounts[0]);
  }

  // **** SWAP (supporting fee-on-transfer tokens) ****
  // requires the initial amount to have already been sent to the first pair
  function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
    for (uint256 i; i < path.length - 1; i++) {
      (address input, address output) = (path[i], path[i + 1]);
      (address token0, ) = PancakeLibraryV2.sortTokens(input, output);
      IPancakePair pair = IPancakePair(PancakeLibraryV2.pairFor(factory, input, output));
      uint256 amountInput;
      uint256 amountOutput;
      {
        // scope to avoid stack too deep errors
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        (uint256 reserveInput, uint256 reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
        amountOutput = PancakeLibraryV2.getAmountOut(amountInput, reserveInput, reserveOutput);
      }
      (uint256 amount0Out, uint256 amount1Out) =
        input == token0 ? (uint256(0), amountOutput) : (amountOutput, uint256(0));
      address to = i < path.length - 2 ? PancakeLibraryV2.pairFor(factory, output, path[i + 2]) : _to;
      pair.swap(amount0Out, amount1Out, to, new bytes(0));
    }
  }

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external virtual override ensure(deadline) {
    SafeToken.safeTransferFrom(path[0], msg.sender, PancakeLibraryV2.pairFor(factory, path[0], path[1]), amountIn);
    uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
    _swapSupportingFeeOnTransferTokens(path, to);
    require(
      IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
      "PancakeRouter: INSUFFICIENT_OUTPUT_AMOUNT"
    );
  }

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable virtual override ensure(deadline) {
    require(path[0] == WETH, "PancakeRouter: INVALID_PATH");
    uint256 amountIn = msg.value;
    IWETH(WETH).deposit{ value: amountIn }();
    assert(IWETH(WETH).transfer(PancakeLibraryV2.pairFor(factory, path[0], path[1]), amountIn));
    uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
    _swapSupportingFeeOnTransferTokens(path, to);
    require(
      IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
      "PancakeRouter: INSUFFICIENT_OUTPUT_AMOUNT"
    );
  }

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external virtual override ensure(deadline) {
    require(path[path.length - 1] == WETH, "PancakeRouter: INVALID_PATH");
    SafeToken.safeTransferFrom(path[0], msg.sender, PancakeLibraryV2.pairFor(factory, path[0], path[1]), amountIn);
    _swapSupportingFeeOnTransferTokens(path, address(this));
    uint256 amountOut = IERC20(WETH).balanceOf(address(this));
    require(amountOut >= amountOutMin, "PancakeRouter: INSUFFICIENT_OUTPUT_AMOUNT");
    IWETH(WETH).withdraw(amountOut);
    SafeToken.safeTransferETH(to, amountOut);
  }

  // **** LIBRARY FUNCTIONS ****
  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) public pure virtual override returns (uint256 amountB) {
    return PancakeLibraryV2.quote(amountA, reserveA, reserveB);
  }

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) public pure virtual override returns (uint256 amountOut) {
    return PancakeLibraryV2.getAmountOut(amountIn, reserveIn, reserveOut);
  }

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) public pure virtual override returns (uint256 amountIn) {
    return PancakeLibraryV2.getAmountIn(amountOut, reserveIn, reserveOut);
  }

  function getAmountsOut(uint256 amountIn, address[] memory path)
    public
    view
    virtual
    override
    returns (uint256[] memory amounts)
  {
    return PancakeLibraryV2.getAmountsOut(factory, amountIn, path);
  }

  function getAmountsIn(uint256 amountOut, address[] memory path)
    public
    view
    virtual
    override
    returns (uint256[] memory amounts)
  {
    return PancakeLibraryV2.getAmountsIn(factory, amountOut, path);
  }
}
