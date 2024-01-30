// SPDX-License-Identifier: MIT

/// @title nonon swap

pragma solidity 0.8.16;

import "./interfaces/INonon.sol";

// errors
error Unauthorized();
error OfferForNonexistentToken();
error NoActiveOffer();
error NotRequestedToken();
error TokenHasExistingOffer();

// state
struct TokenOffer {
    address owner;
    uint16 ownedId;
    uint16 wantedId; // unset (zero) is considered to be open
}

contract NononSwap {
    uint256 public constant nononMaxSupply = 5000;
    address public immutable nononAddress;

    // events
    event OfferCreated(address indexed owner, uint256 indexed ownedId, uint256 indexed wantedId);
    event OfferCancelled(address indexed owner, uint256 indexed ownedId);
    event SwapCompleted(uint256 indexed firstTokenId, uint256 indexed secondTokenId);

    /**
     * @dev Mapping (implemented as an array for gas efficiency) between token
     * ids and token offers. Thus, `offers[0]` should never be defined.
     */
    TokenOffer[nononMaxSupply + 1] public offers;

    constructor(address _nononAddress) {
        nononAddress = _nononAddress;
    }

    /**
     * @dev Create a token swap offer for the owned token `_ownedId` and the
     * wanted token `_wantedId`. It can also be used to update already set
     * offers so the owner doenst need to call `removeOffer` every time they
     * want to change their offer.
     * @param _ownedId Token that `msg.sender` owns and wants to swap for
     * `_wantedId`
     * @param _wantedId Token that `msg.sender` wants, 0 if they dont care
     * and just want to farm friendship points.
     */ 
    function createTokenOffer(uint16 _ownedId, uint16 _wantedId) external {
        INonon nonon = INonon(nononAddress);

        if (!nononExists(_ownedId) || (_wantedId != 0 && !nononExists(_wantedId))) {
            revert OfferForNonexistentToken();
        }

        if (nonon.ownerOf(_ownedId) != msg.sender) {
            revert Unauthorized();
        }

        offers[_ownedId] = TokenOffer({
            owner: msg.sender,
            ownedId: _ownedId,
            wantedId: _wantedId
        });

        emit OfferCreated(msg.sender, _ownedId, _wantedId);
    }

    function completeTokenOffer(uint16 _offerTokenId, uint16 _swapId) external {
        INonon nonon = INonon(nononAddress);

        TokenOffer memory offer = offers[_offerTokenId];

        if (offer.owner == address(0) || !nononExists(_offerTokenId)) {
            revert NoActiveOffer();
        }

        if (offer.wantedId != 0 && _swapId != offer.wantedId) {
            revert NotRequestedToken();
        }

        if (!nononExists(_swapId)) {
            revert OfferForNonexistentToken();
        }

        emit SwapCompleted(_offerTokenId, _swapId);

        assembly {
            sstore(add(offers.slot, _offerTokenId), 0)
        }

        // transfer tokens
        nonon.transferFrom(msg.sender, offer.owner, _swapId);
        nonon.transferFrom(offer.owner, msg.sender, offer.ownedId);
    }

    function removeOffer(uint16 _tokenId) external {
        INonon nonon = INonon(nononAddress);

        if (nonon.ownerOf(_tokenId) != msg.sender) {
            revert Unauthorized();
        }

        assembly {
            sstore(add(offers.slot, _tokenId), 0)
        }

        emit OfferCancelled(msg.sender, _tokenId);
    }

    function nononExists(uint16 tokenId) internal view returns (bool success) {
        (success,) = nononAddress.staticcall(abi.encodeWithSignature("ownerOf(uint256)", tokenId));
    }

    function getAllOffers() external view returns (TokenOffer[nononMaxSupply + 1] memory) {
        return offers;
    }
}
