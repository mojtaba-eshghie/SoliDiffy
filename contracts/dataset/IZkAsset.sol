pragma solidity >=0.5.0 <0.6.0;
/**
 * @title ZkAsset Interface
 * @author AZTEC
 * @dev An interface defining the ZkAsset standard 
 * Copyright Spilsbury Holdings Ltd 2019. All rights reserved.
 **/

contract IZkAsset {

    event CreateZkAsset(
        address indexed aceAddress,
        address indexed linkedTokenAddress,
        uint256 scalingFactor,
        bool indexed _canAdjustSupply,
        bool _canConvert
    );
    event ApprovedAddress(address indexed addressApproved, bytes32 indexed noteHash);
    event CreateNoteRegistry(uint256 noteRegistryId);
    event CreateNote(address indexed owner, bytes32 indexed noteHash, bytes metadata);
    event DestroyNote(address indexed owner, bytes32 indexed noteHash, bytes metadata);
    event ConvertTokens(address indexed owner, uint256 value);
    event RedeemTokens(address indexed owner, uint256 value);
    event UpdateNoteMetaData(address indexed owner, bytes32 indexed noteHash, bytes metadata);
    
    function confidentialApprove(
        bytes32 _noteHash,
        address _spender,
        bool _status,
        bytes calldata _signature
    ) external;

    function confidentialTransferFrom(uint24 _proof, bytes calldata _proofOutput) external;
    
    function confidentialTransfer(bytes memory _proofData, bytes memory _signatures) public;
}
