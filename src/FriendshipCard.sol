// SPDX-License-Identifier: UNLICENSED

/// @title FRIENDSHIP CARD - YOUR SPECIAL GIFT

pragma solidity 0.8.16;

import "ERC721A/ERC721A.sol";
import "ERC721A/IERC721A.sol";
import "solady/auth/OwnableRoles.sol";
import "solady/utils/Base64.sol";
import "solady/utils/LibBitmap.sol";

import "./interfaces/IFriendshipCard.sol";

contract FriendshipCard is IFriendshipCard, ERC721A, OwnableRoles {
    // track tokens that have been collected by a given address
    mapping(address => LibBitmap.Bitmap) private receivedBitmap;
    mapping(address => LibBitmap.Bitmap) private sentBitmap;

    // PLACEHOLDER VALUES
    string public constant TOKEN_NAME = "NONON FRIENDSHIP CARD ";
    string public constant TOKEN_DESCRIPTION = "your friendship card";
    string public constant BASE_IMAGE = "https://pbs.twimg.com/media/Fh-bK3MaMAY0rCv?format=jpg&name=medium";

    address private immutable collectionAddress;

    struct Level {
        uint256 minimum;
        string name;
        string imageURI;
    }

    Level[] public levels;

    constructor(address tokenCollectionAddress) ERC721A("FriendshipCard", "FRIEND") {
        _setOwner(msg.sender);
        collectionAddress = tokenCollectionAddress;

        levels.push(Level(0, "LEVEL 1", BASE_IMAGE));
    }

    function mintTo(address to) external onlyCollection {
        _mint(to, 1);
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

    // get metadata for token display based on a given points value
    function levelData(uint256 tokenPoints) internal view returns (string memory, string memory, uint256) {
        for (uint256 i = levels.length; i > 0;) {
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
            unchecked { --i; }
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

    // add ID for associated sequential tokens to appropriate lists
    function registerTokenMovement(address from, address to, uint256 collectionTokenStartId, uint256 quantity)
        external
        onlyCollection
    {
        // register token id send events for address
        if (from != address(0)) {
            LibBitmap.setBatch(sentBitmap[from], collectionTokenStartId, quantity);
        }

        // register token id receive events for address
        if (to != address(0)) {
            LibBitmap.setBatch(receivedBitmap[to], collectionTokenStartId, quantity);
        }
    }

    // total points accumulated by a holder
    function points(uint256 tokenId) public view returns (uint256) {
        address owner = ownerOf(tokenId);
        uint256 max = IERC721A(collectionAddress).totalSupply() + 1;

        return LibBitmap.popCount(receivedBitmap[owner], 0, max) + LibBitmap.popCount(sentBitmap[owner], 0, max);
    }

    // check if given address is a holder of the token
    function hasToken(address receiver) public view returns (bool) {
        return balanceOf(receiver) > 0;
    }

    // add a new evolution level to the list - must be greater points threshold than previous minimum
    function appendLevel(uint256 minimum, string calldata name, string calldata imageURI) external onlyOwner {
        Level memory lastLevel = levels[levels.length - 1];
        if (lastLevel.minimum >= minimum) revert LevelMinimumLowerThanExisting();

        levels.push(Level(minimum, name, imageURI));
    }

    // remove a level from the list
    function removeLevel(uint256 index) external onlyOwner {
        if (index >= levels.length) return;

        for (uint256 i = index; i < levels.length - 1;) {
            levels[i] = levels[i + 1];
            unchecked { ++i; }
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
