// SPDX-License-Identifier: UNLICENSED

/// @title NONON

pragma solidity ^0.8.13;

import "ERC721A/ERC721A.sol";
import "./interfaces/ILoyaltyCard.sol";

contract Nonon is ERC721A {
    // track loyalty cards minted
    mapping(address => uint256) loyalty;

    ILoyaltyCard private loyaltyCard;

    constructor(address _loyaltyCard) ERC721A("Nonon", "NONON") {
        loyaltyCard = ILoyaltyCard(_loyaltyCard);
    }

    // TEST TEST public mint
    function mint(address to, uint256 quantity) public {
        _mint(to, quantity);
    }

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256) internal override {
        if (to != address(0) && loyaltyCard.balanceOf(to) == 0) {
            loyaltyCard.mintTo(to);
        }

        // TODO: support multi mint factoring in quantity
        loyaltyCard.registerRecievedToken(to, startTokenId);
        loyaltyCard.registerSentToken(from, startTokenId);
    }
}
