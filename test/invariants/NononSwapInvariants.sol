// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "../../src/NononSwap.sol";
import "../../src/Nonon.sol";

contract NononSwapInvariants is NononSwap {

    Nonon nonon = new Nonon();

    constructor() NononSwap(address(nonon)) {
    }

    function assert_impossible_token_never_has_any_offer(uint32 tokenId) public view {
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

    function assert_owner_present_binding(uint16 id) public view {
        TokenOffer memory offer = offers[id];
        require(offer.owner != address(0));
        assert(offer.ownedId == id);
    }

    function assert_owner_ausent_binding(uint16 id) public view {
        uint256 ausentOffer;
        assembly { 
            let offerSlot := add(offers.slot, id)
            ausentOffer := sload(offerSlot) 
        }
        // If the address is zero, everything else should be.
        require(ausentOffer & ((1 << 160) - 1) == 0);
        assert(ausentOffer == 0);
    }

    function assert_offers_always_in_range(uint16 tokenId) public view {
        require(tokenId > 0 && tokenId <= nononMaxSupply);
        TokenOffer memory offer = offers[tokenId];
        assert(offer.ownedId > 0 && offer.ownedId <= nononMaxSupply);
        assert(offer.wantedId > 0 && offer.wantedId <= nononMaxSupply);
    }

    function assert_can_always_create_offer(uint16 ownedToken, uint16 wantedToken) public {
        require(nonon.ownerOf(ownedToken) == msg.sender);
        require(nononExists(wantedToken));
        createTokenOffer(ownedToken, wantedToken);
        TokenOffer memory offer = offers[ownedToken];
        assert(offer.owner == msg.sender);
        assert(offer.ownedId == ownedToken);
        assert(offer.wantedId == wantedToken);
        assert(!offer.completedOrCanceled);
    }
    
    function assert_cant_complete_already_canceled_or_completed_offer(uint16 ownedToken, uint16 wantedToken) public {
        require(nonon.ownerOf(ownedToken) == msg.sender);
        require(nononExists(wantedToken));
        TokenOffer memory offer = offers[wantedToken];
        require(offer.completedOrCanceled);
        completeTokenOffer(wantedToken, ownedToken);
        assert(false);
    }

    function assert_can_complete_offer(uint16 ownedToken, uint16 wantedToken) public {
        require(nonon.ownerOf(ownedToken) == msg.sender);
        TokenOffer memory offer = offers[wantedToken];
        require(offer.wantedId == ownedToken || offer.wantedId == 0);
        assert(offer.ownedId == wantedToken);
        require(!offer.completedOrCanceled);

        require (offer.owner == nonon.ownerOf(wantedToken));
        completeTokenOffer(wantedToken, ownedToken);
        assert(nonon.ownerOf(wantedToken) == msg.sender);
        assert(nonon.ownerOf(ownedToken) == offer.owner);
        TokenOffer memory newOffer = offers[wantedToken];
        assert(newOffer.completedOrCanceled);
        assert(newOffer.owner == offer.owner);
        assert(newOffer.wantedId == offer.wantedId);
        assert(newOffer.ownedId == offer.ownedId);
    }

    function assert_can_update_offer_after_transfer(uint16 ownedToken, uint16 wantedToken) public {
        TokenOffer memory offer = offers[ownedToken];
        require(offer.owner != msg.sender && nonon.ownerOf(ownedToken) == msg.sender);
        require(wantedToken > 0 && wantedToken <= nononMaxSupply);
        createTokenOffer(ownedToken, wantedToken);
        TokenOffer memory newOffer = offers[ownedToken];
        assert(newOffer.owner == msg.sender);
        assert(newOffer.wantedId == wantedToken);
        assert(newOffer.ownedId == ownedToken);
    }

    function assert_owned_id_vs_index_consistency(uint16 id) public view {
        TokenOffer memory offer = offers[id];
        assert(offer.ownedId == id);
    }

    function assert_empty_offer_vs_index_consistency(uint16 id) public view {
        TokenOffer memory offer = offers[id];
        require(offer.owner == address(0));
        assert(offer.ownedId == 0);
        assert(offer.completedOrCanceled == false);
        assert(offer.wantedId == 0);
    }

}
