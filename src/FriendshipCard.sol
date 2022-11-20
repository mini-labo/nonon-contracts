// SPDX-License-Identifier: UNLICENSED

/// @title FRIENDSHIP CARD - YOUR SPECIAL GIFT

pragma solidity ^0.8.13;

import "ERC721A/ERC721A.sol";
import "ERC721A/extensions/ERC721AQueryable.sol";
import "solady/auth/OwnableRoles.sol";
import "solady/utils/Base64.sol";

error OnlyForYou();
error NotAllowed();

contract FriendshipCard is ERC721A, OwnableRoles {
    // track tokens that have been collected by a given address
    mapping(address => mapping(uint256 => bool)) hasReceived;
    mapping(address => mapping(uint256 => bool)) hasSent;

    mapping(address => uint256) receivedCounter;
    mapping(address => uint256) sentCounter;

    string public constant TOKEN_NAME = "NONON FRIENDSHIP CARD";
    string public constant TOKEN_DESCRIPTION = "your friendship card";

    address private collectionAddress;

    constructor() ERC721A("FriendshipCard", "FRIEND") {
        _setOwner(msg.sender);
    }

    function mintTo(address to) external onlyCollection {
        _safeMint(to, 1);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseUrl = "data:application/json;base64,";
        uint256 tokenPoints = points(tokenId);

        return string(
            abi.encodePacked(
                baseUrl,
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            TOKEN_NAME,
                            '",',
                            '"description":"',
                            TOKEN_DESCRIPTION,
                            '",',
                            '"attributes":[{"trait_type":"points","max_value":2000,"value":',
                            _toString(tokenPoints),
                            "}],",
                            '"image":"',
                            tokenImage(tokenPoints),
                            '"}'
                        )
                    )
                )
            )
        );
    }

    function tokenImage(uint256) private pure returns (string memory) {
        // TODO: if x points, return y
        return "https://pbs.twimg.com/media/Fh-bK3MaMAY0rCv?format=jpg&name=medium";
    }

    function _beforeTokenTransfers(address from, address to, uint256, uint256) internal pure override {
        // we stop you losing your card to thieves. its only for you
        if (from != address(0) && to != address(0)) {
            revert OnlyForYou();
        }
    }

    function setCollectionAddress(address _collectionAddress) external onlyOwner {
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
            revert NotAllowed();
        }
        _;
    }
}
