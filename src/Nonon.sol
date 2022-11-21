// SPDX-License-Identifier: UNLICENSED

/// @title NONON

pragma solidity ^0.8.13;

import "ERC721A/ERC721A.sol";
import "./interfaces/IFriendshipCard.sol";

contract Nonon is ERC721A {
    IFriendshipCard private friendshipCard;

    constructor(address _friendshipCard) ERC721A("Nonon", "NONON") {
        friendshipCard = IFriendshipCard(_friendshipCard);
    }

    // TEST TEST public mint
    function mint(address to, uint256 quantity) public {
        _mint(to, quantity);
    }

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        override
    {
        if (to != address(0) && friendshipCard.balanceOf(to) < 1) {
            friendshipCard.mintTo(to);
        }

        for (uint256 i = 0; i < quantity; i++) {
            friendshipCard.registerRecievedToken(to, startTokenId + i);
            friendshipCard.registerSentToken(from, startTokenId + i);
        }
    }
}
