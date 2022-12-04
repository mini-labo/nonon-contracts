// SPDX-License-Identifier: UNLICENSED

/// @title NONON

pragma solidity 0.8.16;

import "ERC721A/ERC721A.sol";
import "solady/auth/OwnableRoles.sol";
import "./interfaces/IFriendshipCard.sol";

error FriendshipTokenZeroAddress();

contract Nonon is ERC721A, OwnableRoles {
    address private friendshipCardAddress;

    event FriendshipTokenAddressSet(address caller, address newTokenAddress);

    constructor() ERC721A("Nonon", "NONON") {
        _setOwner(msg.sender);
    }

    // TEST TEST public mint
    function mint(address to, uint256 quantity) public {
        _mint(to, quantity);
    }

    function setFriendshipCard(address tokenAddress) external onlyOwner {
        if (tokenAddress == address(0)) revert FriendshipTokenZeroAddress();
        friendshipCardAddress = tokenAddress;

        emit FriendshipTokenAddressSet(msg.sender, tokenAddress);
    }

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        override
    {
        IFriendshipCard friendshipCard = IFriendshipCard(friendshipCardAddress);

        if (to != address(0) && !friendshipCard.hasToken(to)) {
            friendshipCard.mintTo(to);
        }

        for (uint256 i = 0; i < quantity; i++) {
            friendshipCard.registerRecievedToken(to, startTokenId + i);
            friendshipCard.registerSentToken(from, startTokenId + i);
        }
    }
}
