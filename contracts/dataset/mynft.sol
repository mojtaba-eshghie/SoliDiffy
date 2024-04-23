// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";



contract TestNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Address for address;

    uint256 private _currentTokenId = 0;

    string private _uri;

    uint256 public _price;

    address private ERC20Contract;

    address private MarketContract;

    address private _verifier;

    // Mapping from token ID to token category
    mapping(uint256 => uint256) private _categories;

    mapping(address => mapping(uint256 => uint256)) public categoriesNftCounter;

    mapping(uint256 => uint256) public allowCountNftForCategories;

    // Mapping set ids to tokens list
    mapping(uint256 => uint256[]) private _sets;

    mapping(uint256 => bool) private usedNonces;

    event SetCreated(address indexed wallet, uint256 _tokenId);
	event Create(address indexed creator, uint256 _tokenId, uint256 _category, string args);


   constructor(string memory _name, string memory _symbol, address cOwner, string memory uri_, address verifier) Ownable(cOwner) ERC721(_name, _symbol) {
        _uri = uri_;
        _verifier = verifier;
    }

    modifier isAllowedQuantityNFT(uint256 _category, address _spender) {
        if (allowCountNftForCategories[_category] != 0) {
            require(categoriesNftCounter[_spender][_category] < allowCountNftForCategories[_category], "Maximum tokens count in a category");
        }
        _;
    }

    modifier onlyMarket() {
        require(_msgSender() == MarketContract, "Only market");
        _;
    }

    function safeTransferToken(address _buyer, address _seller, uint256 _tokenId, uint256 _category) external onlyMarket isAllowedQuantityNFT(_category, _buyer) {
        safeTransferFrom(MarketContract, _buyer, _tokenId);
        incraaseCountTokenInCategory(_buyer, _category);
        decraaseCountTokenInCategory(_seller, _category);       
    }

    function incraaseCountTokenInCategory(address owner, uint256 _category) private {
        categoriesNftCounter[owner][_category]++;
    }

    function decraaseCountTokenInCategory(address owner, uint256 _category) private {
        categoriesNftCounter[owner][_category]--;
    }



    function changeAllowNftForCategories(uint256 _category, uint256 _nftCount) external onlyOwner {
        allowCountNftForCategories[_category] = _nftCount;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(_uri).length > 0 ? string(abi.encodePacked(_uri, tokenId.toString())) : "";
    }


    function setBaseURI(string memory _newuri) public onlyOwner {
        _uri = _newuri;

    }

    function setERC20Contract(address _account) public onlyOwner {
        ERC20Contract = _account;
    }

    function setMarketContract(address _account) public onlyOwner {
        MarketContract = _account;
    }

    function setMintPrice(uint256 _newprice) public onlyOwner {
        _price = _newprice;
    }


    function withdrawOwner() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }


    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId + 1;
    }


    function _incrementTokenId() private {
        _currentTokenId++;
    }

    function getTokenCategory(uint256 _tokenId) public view returns(uint256) {
        return _categories[_tokenId];
    }

    function create(uint256 _category, string memory args, uint256 nonce, bytes memory sig) public payable isAllowedQuantityNFT(_category, _msgSender()) {
        require(!usedNonces[nonce]);
        bytes32 message = prefixed(keccak256(abi.encodePacked(_category, args, nonce, address(this))));
        address signer = recoverSigner(message, sig);
        require(signer ==_verifier, "Unauthorized transaction");

        usedNonces[nonce] = true;

        if (_price > 0) {
            require(msg.value >= _price, "Insufficient BNB to mint token");
            uint256 change = msg.value - _price;
            if (change > 0) {
                payable(_msgSender()).transfer(change);
            }
        }
        uint256 newTokenId = _getNextTokenId();
        _safeMint(_msgSender(), newTokenId);
        _categories[newTokenId] = _category;
        _incrementTokenId();
        incraaseCountTokenInCategory(_msgSender(), _category);
        emit Create(_msgSender(), newTokenId, _category, args);

    }


    function burn(uint256 tokenId, uint256 nonce, bytes memory sig) public  {
        require(!usedNonces[nonce]);
        bytes32 message = prefixed(keccak256(abi.encodePacked(nonce, address(this))));
        address signer = recoverSigner(message, sig);
        require(signer ==_verifier, "Unauthorized transaction");
        usedNonces[nonce] = true;
        require(ownerOf(tokenId) == _msgSender(), "Caller is not an owner of token");
        require(_exists(tokenId), "Token doesn't exist");
        uint256 category = _categories[tokenId];
        decraaseCountTokenInCategory(_msgSender(), category);
        _burn(tokenId);
        delete _categories[tokenId];
    }


    function createFromERC20(address _sender, uint256 _category) public isAllowedQuantityNFT(_category, _sender) returns (uint256) {
        require(_msgSender() == ERC20Contract, "Caller is not authorized to use this function");
        require(_sender != address(0), "Cannot mint to zero address");
        uint256 newTokenId = _getNextTokenId();
        _safeMint(_sender, newTokenId);
        _categories[newTokenId] = _category;
        _incrementTokenId();
        incraaseCountTokenInCategory(_sender, _category);
        return newTokenId;
    }


    function getAllTokensByOwner(address account) public view returns (uint256[] memory) {
        uint256 length = balanceOf(account);
        uint256[] memory result = new uint256[](length);
        for (uint i = 0; i < length; i++)
            result[i] = tokenOfOwnerByIndex(account, i);
        return result;
    }


    function createSet(uint256[] memory _tokens) public {
        require(_tokens.length > 1, "Too few tokens to create set");
        for (uint i = 0; i < _tokens.length; i++) {
            transferFrom(_msgSender(), address(this), _tokens[i]);
        }
        uint256 newTokenId = _getNextTokenId();
        _safeMint(_msgSender(), newTokenId);
        _sets[newTokenId] = _tokens;
        _incrementTokenId();
        emit SetCreated(_msgSender(), newTokenId);
    }


    function redeemSet(uint256 _setId, uint256 nonce, bytes memory sig) public {
        require(!usedNonces[nonce]);
        bytes32 message = prefixed(keccak256(abi.encodePacked(nonce, address(this))));
        address signer = recoverSigner(message, sig);
        require(signer ==_verifier, "Unauthorized transaction");
        usedNonces[nonce] = true;
        require(_exists(_setId), "Set doesn't exist");
        require(_sets[_setId].length > 0, "Invalid Set ID");
        _burn(_setId);
        for (uint i = 0; i < _sets[_setId].length; i++) {
            transferFrom(address(this), _msgSender(), _sets[_setId][i]);
        }
        delete _sets[_setId];
    }

    function recoverSigner(bytes32 message, bytes memory sig) public pure
    returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig)
    public
    pure
    returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }





}