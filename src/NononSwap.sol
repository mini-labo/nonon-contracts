/// @title nonon swap

pragma solidity 0.8.16;

import "./interfaces/INonon.sol";

error Unauthorized();
error OfferForNonexistentToken();
error NoActiveOffer();
error NotRequestedToken();
error TokenHasExistingOffer();

contract NononSwap {
    address public immutable nononAddress;

    // events
    event OfferCreated(address indexed owner, uint256 indexed ownedId, uint256 indexed wantedId, uint256 listingIndex);
    event OfferCancelled(
        address indexed owner, uint256 indexed ownedId, uint256 indexed wantedId, uint256 listingIndex
    );
    event SwapCompleted(uint256 indexed firstTokenId, uint256 indexed secondTokenId, uint256 listingIndex);

    struct TokenOffer {
        address owner;
        uint16 ownedId;
        uint16 wantedId; // unset (zero) is considered to be open
        uint16 listingIndex; // for lookup
    }

    // owned token id => owner
    mapping(uint16 => TokenOffer) public offers;

    // for listing / lookup
    TokenOffer[] public availableOffers;

    constructor(address _nononAddress) {
        nononAddress = _nononAddress;
    }

    function createTokenOffer(uint16 _ownedId, uint16 _wantedId) external {
        INonon nonon = INonon(nononAddress);

        if (!nononExists(_ownedId) || (_wantedId != 0 && !nononExists(_wantedId))) {
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
            listingIndex: uint16(availableOffers.length)
        });

        offers[_ownedId] = offer;
        availableOffers.push(offer);

        emit OfferCreated(msg.sender, _ownedId, _wantedId, offer.listingIndex);
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

        // Swap and pop
        uint256 lastIndex = availableOffers.length - 1;
        uint16 replaceIndex = offer.listingIndex;

        offers[availableOffers[lastIndex].ownedId].listingIndex = replaceIndex;
        availableOffers[replaceIndex] = availableOffers[lastIndex];
        availableOffers[replaceIndex].listingIndex = replaceIndex;
        availableOffers.pop();

        delete offers[_offerTokenId];

        emit SwapCompleted(_offerTokenId, _swapId, offer.listingIndex);

        // transfer tokens
        nonon.transferFrom(msg.sender, offer.owner, _swapId);
        nonon.transferFrom(offer.owner, msg.sender, offer.ownedId);
    }

    function removeOffer(uint16 _tokenId) public {
        INonon nonon = INonon(nononAddress);

        if (nonon.ownerOf(_tokenId) != msg.sender) {
            revert Unauthorized();
        }

        TokenOffer memory offer = offers[_tokenId];

        if (offer.owner == address(0)) {
            revert NoActiveOffer();
        }

        // Swap and pop
        uint256 lastIndex = availableOffers.length - 1;
        uint16 replaceIndex = offer.listingIndex;
        offers[availableOffers[lastIndex].ownedId].listingIndex = replaceIndex;
        availableOffers[replaceIndex] = availableOffers[lastIndex];
        availableOffers[replaceIndex].listingIndex = replaceIndex;
        availableOffers.pop();

        delete offers[_tokenId];

        emit OfferCancelled(offer.owner, offer.ownedId, offer.wantedId, offer.listingIndex);
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

    function nononExists(uint256 tokenId) public view returns (bool) {
        (bool success,) = address(nononAddress).staticcall(abi.encodeWithSignature("ownerOf(uint256)", tokenId));

        return success;
    }
}
