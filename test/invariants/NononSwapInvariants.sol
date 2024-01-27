// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "../../src/NononSwap.sol";
import "../../src/Nonon.sol";

contract NononSwapInvariants is NononSwap {

    Nonon nonon = new Nonon();

    constructor() NononSwap(address(nonon)) {
    }

    function assert_zero_token_never_has_any_offer(uint32 tokenId) public view {
        require(tokenId == 0 || tokenId > nononMaxSupply);

        uint256 impossibleOffer;
        // The whole struct fits into a single word, so this is equivalent
        // to loading `offers[tokenId]`.
        assembly { 
            let offerSlot := add(offers.slot, tokenId)
            impossibleOffer := sload(offerSlot) 
        }
        assert(impossibleOffer == 0);
    }

    function assert_offers_always_in_range(uint16 tokenId) public view {
        require(tokenId > 0 && tokenId <= nononMaxSupply);
        TokenOffer memory offer = offers[tokenId];
        assert(offer.ownedId > 0 && offer.ownedId <= nononMaxSupply);
        assert(offer.wantedId > 0 && offer.wantedId <= nononMaxSupply);
    }

    function assert_can_always_create_offer(uint16 ownedToken, uint16 wantedToken) public view {
        require(nonon.ownerOf(ownedToken) == msg.sender);
        require(nononExists(wantedToken));
        createTokenOffer(ownedId, wantedId);
    }


}
