// SPDX-License-Identifier: MIT
//SWC-103-Floating Pragma: L3, all contract
pragma solidity ^0.8.0;

library Address {
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

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
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    using Address for address;
    using Address for address payable;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public LockList;
    mapping(address => uint256) public LockedTokens;

    mapping(address => uint256) private _firstSell;
    mapping(address => uint256) private _totSells;

    mapping(address => uint256) private _firstBuy;
    mapping(address => uint256) private _totBuy;

    mapping(address => bool) internal _isExcludedFromFee;
    mapping(address => bool) internal _includeInSell;
    mapping(address => bool) internal _isBadActor;

    uint256 public maxSellPerDay = 150 * 10**9;


    uint256 private _totalSupply;
    uint256 public maxTxAmount;

    uint256 public buyLimit = 7000 * 10**9;
    uint256 public sellLimit = 2000 * 10**9;

    uint256 public burnDifference = 11000000000000000;
    uint256 public maxBurnAmount = 502700000000000;

    uint256 public timeLimit;
    uint256 public maxSellPerDayLimit;

    string private _name;
    string private _symbol;
//SWC-108-State Variable Default Visibility: L270
    bool inSwap;
    bool public liquiFlag = true;


    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    IRouter public pancakeRouter;
    address public pancakePair;
    address public pancakeSwapRouter =
        address(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // 10ed43c718714eb63d5aa57b78b54704e256024e for mainnet;
    address public USDT = address(0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47);   // BUSDT tesnet : 0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47 // USDT ropsten : 0xb03Ba6B311aaC34B06bdC97357E6f08BF2c12857
//SWC-108-State Variable Default Visibility: L282-284
    address payable public liquidityWallet =
        payable(0x11cFc68B96A4da8BE01b6450b9bb34fE524cDe91);
    address payable public privateSaleWallet =
        payable(0xa60aCD0B94FfB0c1eD297166ED8a103D069B34bB);
    address payable public marketingWallet =
        payable(0xaffdbd2d37F60E847030c10318C3d501B846f98C);
    address payable public strategicSalesWallet =
        payable(0x7a6bB417E1f547a2cbC18827F1d4193987606b19);
    address payable public gameOperationsWallet =
        payable(0x8e778965508263E7Bc32b4d03A22E6d2eEE41860);
    address payable public teamWallet =
        payable(0xc4536A5E715D578aEF681Fb84809AE0B7CC408C8);
    address payable public communityAirdropWallet =
        payable(0x7dA3F9a354C93A3D049ef42A90081d3a7Fe646E7);
    address payable public burnWallet =
        payable(0xA1dcFAF341C8A45D897977a5593C951b4e21Ff0D);

    struct feeRatesStruct {
        uint256 taxFee;
        uint256 burnFee;
        uint256 airdropFee;
        uint256 marketingFee;
        uint256 liquidityFee;
        uint256 swapFee;
        uint256 totFees;
    }
    struct antiwhale {
        uint256 selling_threshold; //this is value/1000 %
        uint256 extra_tax; //this is value %
    }
//SWC-135-Code With No Effects: L284, L312-315
    feeRatesStruct public buyFees =
        feeRatesStruct({
            taxFee: 0,
            burnFee: 5000,
            airdropFee: 2000,
            liquidityFee: 2000,
            marketingFee: 1000,
            swapFee: 10000, // burnFee+airdropFee+liquidityFee+marketingFee
            totFees: 2
        });

    feeRatesStruct private appliedFees = buyFees; //default value

    struct valuesFromGetValues {
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tSwap;
    }

    event Burn(address indexed from, uint256 value);

    constructor(string memory name_, string memory symbol_) {
        maxSellPerDayLimit = 1000000000;
        timeLimit = block.timestamp;
        _name = name_;
        _symbol = symbol_;
    }
//SWC-129-Typographical Error: L339, 488, 500, 514, 658, 661, 780, 781, 782, 783, 784, 785, 821, 261, 262
   

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }
//SWC-100-Function Default Visibility: L373-381, 393-411, 413-430, 432-443, 445-460, 679-695, 754-756, 758-764, 824-826, 828-830, 832-834, 836-838, 881-883, 972-974, 976-978, 980-982, 984-986, 988-990, 998-1000, 1002-1004, 1010-1012, 1014-1016, 1077-1079
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        uint256 unapprovbal;

        unapprovbal = _balances[msg.sender].sub(
            amount,
            "ERC20: Allowance exceeds balance of approver"
        );
        require(
            unapprovbal >= LockedTokens[msg.sender],
            "ERC20: Approval amount exceeds locked amount "
        );
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(
            !_isBadActor[sender] && !_isBadActor[recipient],
            "Bots are not allowed"
        );

        if (!_isExcludedFromFee[sender] && !_isExcludedFromFee[recipient]) {
            require(amount <= maxTxAmount, "you are exceeding maxTxAmount");
        }

        if (recipient == pancakePair) {
            require(_includeInSell[sender], "ERC20:Not allowed to sell");

            if (!liquiFlag) {
                if (maxSellPerDayLimit + amount > maxSellPerDay) {
                    require(
                        block.timestamp > timeLimit + 24 * 1 hours,
                        "maxSellPerDay Limit Exceeded"
                    );
                    timeLimit = block.timestamp;
                    maxSellPerDayLimit = 1000000000;
                }
                if (block.timestamp < _firstSell[sender] + 24 * 1 hours) {
                    require(
                        _totSells[sender] + amount <= sellLimit,
                        "You can't sell more than sellLimit"
                    );
                    _totSells[sender] += amount;
//SWC-122-Lack of Proper Signature Verification: L497-502，511-516
                    if (block.timestamp < timeLimit + 24 * 1 hours) {
                        maxSellPerDayLimit += amount;
                    } else if (block.timestamp > timeLimit + 24 * 1 hours) {
                        maxSellPerDayLimit = 1000000000;
                        timeLimit = block.timestamp;
                    }
                } else {
                    require(
                        amount <= sellLimit,
                        "You can't sell more than sellLimit"
                    );
                    _firstSell[sender] = block.timestamp;
                    _totSells[sender] = amount;

                    if (block.timestamp < timeLimit + 24 * 1 hours) {
                        maxSellPerDayLimit += amount;
                    } else if (block.timestamp > timeLimit + 24 * 1 hours) {
                        maxSellPerDayLimit = 1000000000;
                        timeLimit = block.timestamp;
                    }
                }
            }
        }
        if (sender == pancakePair) {
            if (block.timestamp < _firstBuy[recipient] + 24 * 1 hours) {
                require(
                    _totBuy[recipient] + amount <= buyLimit,
                    "You can't sell more than buyLimit"
                );
                _totBuy[recipient] += amount;
            } else {
                require(
                    amount <= buyLimit,
                    "You can't sell more than buyLimit"
                );
                _firstBuy[recipient] = block.timestamp;
                _totBuy[recipient] = amount;
            }
        }

        require(LockList[_msgSender()] == false, "ERC20: Caller Locked !");
        require(LockList[sender] == false, "ERC20: Sender Locked !");
        require(LockList[recipient] == false, "ERC20: Receipient Locked !");

        uint256 senderBalance = _balances[sender];
        uint256 stage;
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        stage = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        require(
            stage >= LockedTokens[sender],
            "ERC20: transfer amount exceeds Senders Locked Amount"
        );

        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        bool isSale = false;

        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            takeFee = false;
            if (recipient == pancakePair) {
                isSale = true;
            }
        } else {
            if (recipient == pancakePair) {
                isSale = true;
            }
        } 

         _transfeTokens(sender, recipient, amount, takeFee, isSale);
    }

    function _transfeTokens(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee,
        bool isSale
    ) internal virtual {
        if (isSale) {
            unchecked {
                _balances[sender] = _balances[sender] - amount;
            }
            _balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);
        } else {
            appliedFees = buyFees;
            valuesFromGetValues memory s = _getValues(amount, takeFee);

            unchecked {
                _balances[sender] = _balances[sender] - amount;
            }
            _balances[recipient] += s.tTransferAmount;

            if (takeFee) {
                _takeSwapFees(s.tFee + s.tSwap);
            }

            emit Transfer(sender, recipient, s.tTransferAmount);
        }
    }

    function swapAndSendToFees(uint256 tokens) internal virtual {
        uint256 initialBalance = address(this).balance;
        swapTokensForBNB(tokens);
        uint256 transferBalance = address(this).balance - initialBalance;
        liquidityWallet.sendValue(
            (transferBalance * appliedFees.liquidityFee) / appliedFees.swapFee
        );
        communityAirdropWallet.sendValue(
            (transferBalance * appliedFees.airdropFee) / appliedFees.swapFee
        );
        burnWallet.sendValue(
            (transferBalance * appliedFees.burnFee) / appliedFees.swapFee
        );
        marketingWallet.sendValue(address(this).balance);
    }

    function swapTokensForBNB(uint256 tokenAmount)
        internal
        virtual
        lockTheSwap
    {
        // generate the pancakeswap pair path of token -> wbnb
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        if (allowance(address(this), address(pancakeRouter)) < tokenAmount) {
            _approve(address(this), address(pancakeRouter), ~uint256(0));
        }

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function _getValues(uint256 _amount, bool takeFee)
        private
        view
        returns (valuesFromGetValues memory to_return)
    {
        if (!takeFee) {
            to_return.tTransferAmount = _amount;
            to_return.tFee = 0;
            to_return.tSwap = 0;
            return to_return;
        } else if (takeFee)
            to_return.tFee =
                (_amount * appliedFees.totFees * appliedFees.taxFee) /
                1000000;
        to_return.tSwap =
            (_amount * appliedFees.totFees * appliedFees.swapFee) /
            1000000;
        to_return.tTransferAmount = _amount - to_return.tFee - to_return.tSwap;

        return to_return;
    }

    function _takeSwapFees(uint256 tFee) private {
        _balances[address(this)] += tFee;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function burn(uint256 _value) public returns (bool) {
        require(LockList[msg.sender] == false, "ERC20: User Locked !");

        uint256 stage;
        stage = _balances[msg.sender].sub(
            _value,
            "ERC20: transfer amount exceeds balance"
        );
        require(
            stage >= LockedTokens[msg.sender],
            "ERC20: transfer amount exceeds  Locked Amount"
        );

        _burn(_msgSender(), _value);

        return true;
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Burn(account, amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        if (owner != liquidityWallet) {
            if (burnDifference - totalSupply() < maxBurnAmount) {
                if (spender == pancakeSwapRouter) {
                    uint256 burnAmt = amount / 100;
                    _burn(_msgSender(), burnAmt);
                }
            }
        }

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract DoxyFinance_V3 is ERC20, Ownable {
    address payable public stakeAddress =
        payable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);

    bool takeStakeFees = false;

    constructor() ERC20("Doxy Finance", "DOXY_V3") {
        _mint(liquidityWallet, 6362400000000000);
        _mint(marketingWallet, 2168100000000000);
        _mint(strategicSalesWallet, 592900000000000);
        _mint(gameOperationsWallet, 1238600000000000);
        _mint(teamWallet, 484000000000000);
        _mint(communityAirdropWallet, 154000000000000);

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[liquidityWallet] = true;
        _isExcludedFromFee[privateSaleWallet] = true;
        _isExcludedFromFee[marketingWallet] = true;
        _isExcludedFromFee[strategicSalesWallet] = true;
        _isExcludedFromFee[gameOperationsWallet] = true;
        _isExcludedFromFee[teamWallet] = true;
        _isExcludedFromFee[communityAirdropWallet] = true;
        _isExcludedFromFee[burnWallet] = true;
        _isExcludedFromFee[address(this)] = true;

        _includeInSell[owner()] = true;
        _includeInSell[liquidityWallet] = true;
        _includeInSell[privateSaleWallet] = true;
        _includeInSell[marketingWallet] = true;
        _includeInSell[strategicSalesWallet] = true;
        _includeInSell[gameOperationsWallet] = true;
        _includeInSell[teamWallet] = true;
        _includeInSell[communityAirdropWallet] = true;
        _includeInSell[burnWallet] = true;
        _includeInSell[address(this)] = true;
//SWC-135-Code With No Effects: L809-818
        IRouter _pancakeRouter = IRouter(
            0xD99D1c33F9fC3444f8101754aBC46c52416550D1 // replace with 0x10ED43C718714eb63d5aA57B78B54704E256024E while deploying to mainnet
        );

        pancakePair = IFactory(_pancakeRouter.factory()).createPair(
            address(this),
            _pancakeRouter.WETH()
        );

        pancakeRouter = _pancakeRouter;
        setStakeAddress(stakeAddress);

        maxTxAmount = 110000000000000;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function excludeFromSell(address account) public onlyOwner {
        _includeInSell[account] = false;
    }

    function includeInSell(address account) public onlyOwner {
        _includeInSell[account] = true;
    }

    //to recieve ETH from pancakeRouter when swaping
    receive() external payable {}

    function badActorDefenseMechanism(address account, bool isBadActor)
        external
        onlyOwner
    {
        _isBadActor[account] = isBadActor;
    }

    function checkBadActor(address account) public view returns (bool) {
        return _isBadActor[account];
    }

    function rescueBNBFromContract() external onlyOwner {
        address payable _owner = payable(msg.sender);
        _owner.transfer(address(this).balance);
    }

    
    function manualSwap() external onlyOwner {
        uint256 tokensToSwap = balanceOf(address(this));
        swapTokensForBNB(tokensToSwap);
    }

    function setStakeFeesFlag(bool flag) external {
        takeStakeFees = flag;
    }

    function staking(uint256 _amount) external {
       
        require(_amount <= balanceOf(_msgSender()), "Insufficent Balance");
        _transfeTokens(_msgSender(), stakeAddress , _amount, takeStakeFees, false);
    }

    

    function manualSend() external onlyOwner {
        swapAndSendToFees(balanceOf(address(this)));
    }

    function setmaxTxAmount(uint256 _maxTxAmount) public onlyOwner {
        maxTxAmount = _maxTxAmount;
    }

    function setBurnWallet(address payable _address)
        external
        onlyOwner
        returns (bool)
    {
        burnWallet = _address;
        _isExcludedFromFee[burnWallet] = true;
        _includeInSell[burnWallet] = true;

        return true;
    } 

    function whitelistWallet(address payable _address) internal {
         _isExcludedFromFee[_address] = true;
         _includeInSell[_address] = true;
    }

    function setMarketingWallet(address payable _address)
        external
        onlyOwner
        returns (bool)
    {
        marketingWallet = _address;
        whitelistWallet(marketingWallet) ; 
        return true;
    }

    function setLiquidityWallet(address payable _address)
        external
        onlyOwner
        returns (bool)
    {
        liquidityWallet = _address;
        whitelistWallet(marketingWallet) ; 
        return true;
    }
//SWC-129-Typographical Error: L918, 928, 938, 948, 958, 968
    function setAirdropWallet(address payable _address)
        external
        onlyOwner
        returns (bool)
    {
        communityAirdropWallet = _address;
        whitelistWallet(marketingWallet) ; 
        return true;
    }

    function setPrivateSaleWallet(address payable _address)
        external
        onlyOwner
        returns (bool)
    {
        privateSaleWallet = _address;
        whitelistWallet(marketingWallet) ; 
        return true;
    }

    function setStrategicSalesWallet(address payable _address)
        external
        onlyOwner
        returns (bool)
    {
        strategicSalesWallet = _address;
        whitelistWallet(marketingWallet) ; 
        return true;
    }

    function setGameOperationsWallet(address payable _address)
        external
        onlyOwner
        returns (bool)
    {
        gameOperationsWallet = _address;
        whitelistWallet(marketingWallet) ; 
        return true;
    }

    function setTeamWallet(address payable _address)
        external
        onlyOwner
        returns (bool)
    {
        teamWallet = _address;
        whitelistWallet(marketingWallet) ; 
        return true;
    }

    function setBurnDifference(uint256 _burnDifference) public onlyOwner {
        burnDifference = _burnDifference;
    }

    function setMaxBurnAmount(uint256 _maxBurnAmount) public onlyOwner {
        maxBurnAmount = _maxBurnAmount;
    }

    function UserLock(address Account, bool mode) public onlyOwner {
        LockList[Account] = mode;
    }

    function LockTokens(address Account, uint256 amount) public onlyOwner {
        LockedTokens[Account] = amount;
    }

    function UnLockTokens(address Account) public onlyOwner {
        LockedTokens[Account] = 0;
    }

    function mint(uint256 amount) external onlyOwner {
        _mint(msg.sender, amount);
    }

    // Follwoing are the setter function of the contract  :

    function setTimeLimit(uint256 value) public onlyOwner {
        timeLimit = value;
    }

    function setMaxSellPerDayLimit(uint256 value) public onlyOwner {
        maxSellPerDayLimit = value;
    }

    function setStakeAddress(address payable _address) public onlyOwner {
        stakeAddress = _address;
    }

    function setBuylimit(uint256 limit) public onlyOwner {
        buyLimit = limit;
    }

    function setSelllimit(uint256 limit) public onlyOwner {
        sellLimit = limit;
    }

    function setBuyFees(
        uint256 taxFee,
        uint256 burnFee,
        uint256 airdropFee,
        uint256 marketingFee,
        uint256 liquidityFee
    ) external onlyOwner {
        buyFees.taxFee = taxFee;
        buyFees.burnFee = burnFee;
        buyFees.airdropFee = airdropFee;
        buyFees.marketingFee = marketingFee;
        buyFees.liquidityFee = liquidityFee;
        buyFees.swapFee = marketingFee + airdropFee + burnFee + liquidityFee;
        require(
            buyFees.swapFee + buyFees.taxFee == 10000,
            "sum of all percentages should be 10000"
        );
    }

    function setRouterAddress(address newRouter) external onlyOwner {
        require(address(pancakeRouter) != newRouter, "Router already set");
        //give the option to change the router down the line
        IRouter _newRouter = IRouter(newRouter);
        address get_pair = IFactory(_newRouter.factory()).getPair(
            address(this),
            _newRouter.WETH()
        );
        //checks if pair already exists
        if (get_pair == address(0)) {
            pancakePair = IFactory(_newRouter.factory()).createPair(
                address(this),
                _newRouter.WETH()
            );
        } else {
            pancakePair = get_pair;
        }
        pancakeRouter = _newRouter;
    }

    function setTotalBuyFees(uint256 _totFees) external onlyOwner {
        buyFees.totFees = _totFees;
    }

    function setMaxSellAmountPerDay(uint256 amount) external onlyOwner {
        maxSellPerDay = amount * 10**9;
    }

    

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function isIncludeInSell(address account) public view returns (bool) {
        return _includeInSell[account];
    }

    

    function setliquiFlag() public onlyOwner {
        liquiFlag = !liquiFlag;
    }

    function airdrop(
        address[] calldata _contributors,
        uint256[] calldata _balances
    ) external onlyOwner {
        uint8 i = 0;
        for (i; i < _contributors.length; i++) {
            _transfer(owner(), _contributors[i], _balances[i]);
        }
    }

    function preSale(
        address[] calldata _contributors,
        uint256[] calldata _balances
    ) external onlyOwner {
        uint8 i = 0;
        for (i; i < _contributors.length; i++) {
            _transfer(owner(), _contributors[i], _balances[i]);
        }
    }


    function rescueBEPTokenFromContract() external onlyOwner {
        IERC20 ERC20Token = IERC20(address(this));
        address payable _owner = payable(msg.sender);
        ERC20Token.transfer(_owner, address(this).balance);
    }
}