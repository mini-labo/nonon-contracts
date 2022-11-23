// SPDX-License-Identifier: UNLICENSED

/// @title FRIENDSHIP CARD - YOUR SPECIAL GIFT

pragma solidity 0.8.16;

import "ERC721A/ERC721A.sol";
import "ERC721A/IERC721A.sol";
import "solady/auth/OwnableRoles.sol";
import "solady/utils/Base64.sol";

import "./interfaces/IFriendshipCard.sol";

contract FriendshipCard is IFriendshipCard, ERC721A, OwnableRoles {
    // track tokens that have been collected by a given address
    mapping(address => mapping(uint256 => bool)) hasReceived;
    mapping(address => mapping(uint256 => bool)) hasSent;

    mapping(address => uint256) receivedCounter;
    mapping(address => uint256) sentCounter;

    string public constant TOKEN_NAME = "NONON FRIENDSHIP CARD ";
    string public constant TOKEN_DESCRIPTION = "your friendship card";
    string public constant BASE_IMAGE = "https://pbs.twimg.com/media/Fh-bK3MaMAY0rCv?format=jpg&name=medium";

    address private collectionAddress;

    struct Level {
        uint16 minimum;
        string name;
        string imageURI;
    }

    Level[] public levels;

    constructor() ERC721A("FriendshipCard", "FRIEND") {
        _setOwner(msg.sender);

        levels.push(Level(0, "LEVEL 1", BASE_IMAGE));
    }

    function mintTo(address to) external onlyCollection {
        _safeMint(to, 1);
    }

    function burnToken(uint256 tokenId) public {
        _burn(tokenId, true);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        uint256 tokenPoints = points(tokenId);

        (string memory nameSuffix, string memory tokenImage, uint256 levelCap) = levelData(tokenPoints);

        string memory baseUrl = "data:application/json;base64,";

        return string(
            abi.encodePacked(
                baseUrl,
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            string.concat(TOKEN_NAME, nameSuffix),
                            '",',
                            '"description":"',
                            TOKEN_DESCRIPTION,
                            '",',
                            '"attributes":[{"trait_type":"points","max_value":',
                            _toString(levelCap),
                            ',"value":',
                            _toString(tokenPoints),
                            "}],",
                            '"image":"',
                            tokenImage,
                            '"}'
                        )
                    )
                )
            )
        );
    }

    function levelData(uint256 tokenPoints) internal view returns (string memory, string memory, uint256) {
        for (uint256 i = levels.length; i > 0; i--) {
            Level memory level = levels[i - 1];
            if (tokenPoints >= level.minimum) {
                if (i < levels.length) {
                    // there is at least one level above current, so get its minimum
                    Level memory nextLevel = levels[i];
                    return (level.name, level.imageURI, nextLevel.minimum);
                } else {
                    // highest level
                    uint256 maxPoints = IERC721A(collectionAddress).totalSupply() * 2;
                    return (level.name, level.imageURI, maxPoints);
                }
            }
        }

        // fallback
        uint256 maxCollectionPoints = IERC721A(collectionAddress).totalSupply() * 2;
        return ("LEVEL 1", BASE_IMAGE, maxCollectionPoints);
    }

    // prevent transfer (except mint and burn)
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

    // add a new evolution level to the list - must be greater than previous minimum
    function appendLevel(uint16 minimum, string calldata name, string calldata imageURI) external onlyOwner {
        Level memory lastLevel = levels[levels.length - 1];
        if (lastLevel.minimum >= minimum) revert LevelMinimumLowerThanExisting();

        levels.push(Level(minimum, name, imageURI));
    }

    // remove a level from the list
    function removeLevel(uint256 index) external onlyOwner {
        if (index >= levels.length) return;

        for (uint256 i = index; i < levels.length - 1; i++) {
            levels[i] = levels[i + 1];
        }

        levels.pop();
    }

    modifier onlyCollection() {
        if (msg.sender != collectionAddress) {
            revert Unauthorized();
        }
        _;
    }
}
