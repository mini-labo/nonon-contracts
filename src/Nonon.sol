// SPDX-License-Identifier: UNLICENSED

/// @title NONON

pragma solidity 0.8.16;

import "ERC721A/ERC721A.sol";
import "solady/auth/OwnableRoles.sol";
import "./interfaces/INononFriendCard.sol";

error FriendshipTokenZeroAddress();

contract Nonon is ERC721A, OwnableRoles {
    address private friendCardAddress;

    event FriendshipTokenAddressSet(address caller, address newTokenAddress);

    constructor() ERC721A("Nonon", "NONON") {
        _setOwner(msg.sender);
    }

    // TEST TEST public mint
    function mint(address to, uint256 quantity) public {
        _mint(to, quantity);
    }

    // start at 1 so we can reserve 0 for open swap address
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function setFriendshipCard(address tokenAddress) external onlyOwner {
        if (tokenAddress == address(0)) revert FriendshipTokenZeroAddress();
        friendCardAddress = tokenAddress;

        emit FriendshipTokenAddressSet(msg.sender, tokenAddress);
    }

    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        override
    {
        INononFriendCard friendshipCard = INononFriendCard(friendCardAddress);

        if (to != address(0) && !friendshipCard.hasToken(to)) {
            friendshipCard.mintTo(to);
        }

        friendshipCard.registerTokenMovement(from, to, startTokenId, quantity);
    }
}
