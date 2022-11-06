// SPDX-License-Identifier: UNLICENSED

/// @title LOYALTY CARD - YOUR SPECIAL GIFT

// notes:
// we can have the card exist entirely on chain, so that tokenURI can handle 

pragma solidity ^0.8.13;

import "openzeppelin-contracts/token/ERC721/ERC721.sol";

error OnlyForYou();

contract LoyaltyCard is ERC721 {
    // track tokens that have been collected by an address
    mapping(address => uint256[]) public collectedTokens;
    mapping(address => mapping(address => bool)) public hasCollected;

    constructor() ERC721("LoyaltyCard", "LOYAL") {
        _mint(msg.sender, 1);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal override {
        // we stop you losing your card to thieves. its only for you
        if (from != address(0)) {
            revert OnlyForYou();
        }

        super._beforeTokenTransfer(from, to, 1, batchSize);
    }
}
