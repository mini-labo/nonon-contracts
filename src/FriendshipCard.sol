// SPDX-License-Identifier: UNLICENSED

/// @title FRIENDSHIP CARD - YOUR SPECIAL GIFT

pragma solidity 0.8.16;

import "ERC721A/ERC721A.sol";
import "solady/auth/OwnableRoles.sol";
import "solady/utils/Base64.sol";

import "./interfaces/IFriendshipCard.sol";

contract FriendshipCard is IFriendshipCard, ERC721A, OwnableRoles {
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

    function burnToken(uint256 tokenId) public {
        _burn(tokenId, true);
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
        if (from != address(0) && to != address(0)) {
            revert OnlyForYou();
        }
    }

    function setCollectionAddress(address newAddress) external onlyOwner {
        if (newAddress == address(0)) revert CollectionZeroAddress();

        collectionAddress = newAddress;
        emit CollectionAddressSet(msg.sender, newAddress);
    }

    function registerRecievedToken(address owner, uint256 collectionTokenId) external onlyCollection {
        if (!hasReceived[owner][collectionTokenId]) {
            hasReceived[owner][collectionTokenId] = true;
            receivedCounter[owner] += 1;
        }
    }

    function registerSentToken(address owner, uint256 collectionTokenId) external onlyCollection {
        if (!hasSent[owner][collectionTokenId]) {
            hasSent[owner][collectionTokenId] = true;
            sentCounter[owner] += 1;
        }
    }

    function points(uint256 tokenId) public view returns (uint256) {
        address owner = ownerOf(tokenId);
        return receivedCounter[owner] + sentCounter[owner];
    }

    function hasToken(address receiver) public view returns (bool) {
        return balanceOf(receiver) > 0;
    }

    modifier onlyCollection() {
        if (msg.sender != collectionAddress) {
            revert Unauthorized();
        }
        _;
    }
}
