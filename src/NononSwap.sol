/// @title NONON

pragma solidity 0.8.16;

import "./interfaces/INonon.sol";

error Unauthorized();
error OfferForNonexistentToken();
error NoActiveOffer();
error NotRequestedToken();
error TokenHasExistingOffer();

contract NononSwap {
    address private immutable nononAddress;

    struct TokenOffer {
        address owner;
        uint256 ownedId;
        uint256 wantedId; // unset (zero) is considered to be open
        uint256 listingIndex; // for lookup
    }

    // owned token id => owner
    mapping(uint256 => TokenOffer) public offers;

    // for listing / lookup
    TokenOffer[] public availableOffers;

    constructor(address _nononAddress) {
        nononAddress = _nononAddress;
    }

    function createTokenOffer(uint256 _ownedId, uint256 _wantedId) external {
        INonon nonon = INonon(nononAddress);

        if (!nonon.exists(_ownedId) || (_wantedId != 0 && !nonon.exists(_wantedId))) {
            revert OfferForNonexistentToken();
        }

        if (nonon.ownerOf(_ownedId) != msg.sender) {
            revert Unauthorized();
        }

        if (offers[_ownedId].owner != address(0)) {
            revert TokenHasExistingOffer();
        }

        TokenOffer memory offer = TokenOffer({
            owner: msg.sender,
            ownedId: _ownedId,
            wantedId: _wantedId,
            // note: below is accurate to 0 based index since it happens before push
            listingIndex: availableOffers.length
        });

        offers[_ownedId] = offer;
        availableOffers.push(offer);
    }

    function completeTokenOffer(uint256 _offerTokenId, uint256 _swapId) external {
        INonon nonon = INonon(nononAddress);

        TokenOffer memory offer = offers[_offerTokenId];

        if (offer.owner == address(0) || !nonon.exists(_offerTokenId)) {
            revert NoActiveOffer();
        }

        if (offer.wantedId != 0 && _swapId != offer.wantedId) {
            revert NotRequestedToken();
        }

        if (!nonon.exists(_swapId)) {
            revert OfferForNonexistentToken();
        }

        // remove offer
        availableOffers[offer.listingIndex] = availableOffers[availableOffers.length - 1];
        availableOffers.pop();
        delete offers[_offerTokenId];

        // transfer tokens
        nonon.transferFrom(msg.sender, offer.owner, _swapId);
        nonon.transferFrom(offer.owner, msg.sender, offer.ownedId);
    }

    function removeOffer(uint256 _tokenId) public {
        INonon nonon = INonon(nononAddress);

        if (nonon.ownerOf(_tokenId) != msg.sender) {
            revert Unauthorized();
        }

        TokenOffer memory offer = offers[_tokenId];

        if (offer.listingIndex == 0) {
            revert NoActiveOffer();
        }

        availableOffers[offer.listingIndex] = availableOffers[availableOffers.length - 1];
        availableOffers.pop();

        delete offers[_tokenId];
    }

    function getAllAvailableOffers() public view returns (TokenOffer[] memory) {
        return availableOffers;
    }

    function getAvailableOffersByToken(uint256 _wantedTokenId) public view returns (TokenOffer[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < availableOffers.length; i++) {
            if (availableOffers[i].wantedId == _wantedTokenId) {
                count++;
            }
        }

        TokenOffer[] memory matchingOffers = new TokenOffer[](count);
        uint256 j = 0;
        for (uint256 i = 0; i < availableOffers.length; i++) {
            if (availableOffers[i].wantedId == _wantedTokenId) {
                matchingOffers[j] = availableOffers[i];
                j++;
            }
        }

        return matchingOffers;
    }
}