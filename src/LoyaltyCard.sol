// SPDX-License-Identifier: UNLICENSED

/// @title LOYALTY CARD - YOUR SPECIAL GIFT

pragma solidity ^0.8.13;

import "ERC721A/ERC721A.sol";
import "ERC721A/extensions/ERC721AQueryable.sol";

error OnlyForYou();
error Unauthorized();

contract LoyaltyCard is ERC721A, ERC721AQueryable {
    // track tokens that have been collected by a given address
    mapping(address => mapping(uint256 => bool)) hasReceived;
    mapping(address => mapping(uint256 => bool)) hasSent;

    // address => count
    mapping(address => uint256) receivedCounter;
    mapping(address => uint256) sentCounter;

    address private collectionAddress;

    constructor() ERC721A("LoyaltyCard", "LOYAL") {}

    function mintTo(address to) external onlyCollection {
        _safeMint(to, 1);
    }

    function _beforeTokenTransfers(address from, address, uint256, uint256) internal pure override {
        // we stop you losing your card to thieves. its only for you
        if (from != address(0)) {
            revert OnlyForYou();
        }
    }

    // TODO: only owner
    function setCollectionAddress(address _collectionAddress) external {
        collectionAddress = _collectionAddress;
    }

    function registerRecievedToken(address _owner, uint256 _collectionTokenId) external onlyCollection {
        if (!hasReceived[_owner][_collectionTokenId]) {
            hasReceived[_owner][_collectionTokenId] = true;
            receivedCounter[_owner] += 1;
        }
    }

    function registerSentToken(address _owner, uint256 _collectionTokenId) external onlyCollection {
        if (!hasSent[_owner][_collectionTokenId]) {
            hasSent[_owner][_collectionTokenId] = true;
            sentCounter[_owner] += 1;
        }
    }

    function points(uint256 _tokenId) public view returns (uint256) {
        address owner = ownerOf(_tokenId);
        return receivedCounter[owner] + sentCounter[owner];
    }

    modifier onlyCollection() {
        if (msg.sender != collectionAddress) {
            revert Unauthorized();
        }
        _;
    }
}
