// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/**
 * @title IERC721Time
 * @author Lens
 *
 * @notice This is an expansion of the IERC721 interface that includes a struct for token data,
 * which contains the token owner and the mint timestamp as well as associated getters.
 */
interface IERC721Time is IERC721 {
    /**
     * @notice Contains the owner address and the mint timestamp for every NFT.
     *
     * Note: Instead of the owner address in the _tokenOwners private mapping, we now store it in the
     * _tokenData mapping, alongside the unchanging mintTimestamp.
     *
     * @param owner The token owner.
     * @param mintTimestamp The mint timestamp.
     */
    struct TokenData {
        address owner;
        uint96 mintTimestamp;
    }

    /**
     * @notice Returns the mint timestamp associated with a given NFT, stored only once upon initial mint.
     *
     * @param tokenId The token ID of the NFT to query the mint timestamp for.
     *
     * @return The mint timestamp, this is stored as a uint96 but returned as a uint256 to reduce unnecessary
     * padding.
     */
    function mintTimestampOf(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Returns the token data associated with a given NFT. This allows fetching the token owner and
     * mint timestamp in a single call.
     *
     * @param tokenId The token ID of the NFT to query the token data for.
     *
     * @return The token data struct containing both the owner address and the mint timestamp.
     */
    function tokenDataOf(uint256 tokenId) external view returns (TokenData memory);
}
