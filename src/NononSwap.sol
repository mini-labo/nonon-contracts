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
    event OfferCreated(address indexed owner, uint256 indexed ownedId, uint256 indexed wantedId);
    event OfferCancelled(address indexed owner, uint256 indexed ownedId, uint256 indexed wantedId);
    event SwapCompleted(uint256 indexed firstTokenId, uint256 indexed secondTokenId);

    struct TokenOffer {
        address owner;
        uint16 ownedId;
        uint16 wantedId; // unset (zero) is considered to be open
        bool completedOrCanceled;
    }

    // for listing / lookup
    TokenOffer[2**16] public offers;

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

        TokenOffer memory offer = TokenOffer({
            owner: msg.sender,
            ownedId: _ownedId,
            wantedId: _wantedId,
            completedOrCanceled: false
        });

        offers[_ownedId] = offer;

        emit OfferCreated(msg.sender, _ownedId, _wantedId);
    }

    function completeTokenOffer(uint16 _offerTokenId, uint16 _swapId) external {
        INonon nonon = INonon(nononAddress);

        TokenOffer memory offer = offers[_offerTokenId];

        if (offer.completedOrCanceled || offer.owner == address(0) || !nononExists(_offerTokenId)) {
            revert NoActiveOffer();
        }

        if (offer.wantedId != 0 && _swapId != offer.wantedId) {
            revert NotRequestedToken();
        }

        if (!nononExists(_swapId)) {
            revert OfferForNonexistentToken();
        }

        emit SwapCompleted(_offerTokenId, _swapId);
        offer.completedOrCanceled = true;
        offers[_offerTokenId] = offer;

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

        if (offer.completedOrCanceled || offer.owner == address(0)) {
            revert NoActiveOffer();
        }

        // Swap and pop
        offer.completedOrCanceled = true;
        offers[_tokenId] = offer;

        emit OfferCancelled(offer.owner, offer.ownedId, offer.wantedId);
    }

    // TODO Filter completed offers, it can be done from a front-end.
    // function getAllAvailableOffers() public view returns (TokenOffer[] memory) {
    //     return offers;
    // }

    function getAvailableOffersByToken(uint256 _wantedTokenId) public view returns (TokenOffer[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < offers.length; i++) {
            if (offers[i].wantedId == _wantedTokenId) {
                count++;
            }
        }

        TokenOffer[] memory matchingOffers = new TokenOffer[](count);
        uint256 j = 0;
        for (uint256 i = 0; i < offers.length; i++) {
            if (offers[i].wantedId == _wantedTokenId) {
                matchingOffers[j] = offers[i];
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
