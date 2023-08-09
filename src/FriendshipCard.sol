// SPDX-License-Identifier: UNLICENSED

/// @title FRIENDSHIP CARD - YOUR SPECIAL GIFT

pragma solidity 0.8.16;

import "ERC721A/ERC721A.sol";
import "ERC721A/interfaces/IERC721A.sol";
import "solady/auth/OwnableRoles.sol";
import "solady/utils/Base64.sol";
import "solady/utils/SSTORE2.sol";
import "solady/utils/LibBitmap.sol";

import "./interfaces/IFriendshipCard.sol";

contract FriendshipCard is IFriendshipCard, ERC721A, OwnableRoles {
    using LibBitmap for LibBitmap.Bitmap;

    // track tokens that have been collected by a given address
    mapping(address => LibBitmap.Bitmap) private receivedBitmap;
    mapping(address => LibBitmap.Bitmap) private sentBitmap;

    // PLACEHOLDER VALUES
    string public constant TOKEN_NAME = "NONON FRIENDSHIP CARD ";
    string public constant DEFAULT_DESC = "friends forever";

    address public immutable collectionAddress;

    // address where bytes for base SVG are stored
    address private baseSvgPointer;

    struct Level {
        uint256 minimum;
        string name;
        string colorHex;
    }

    // the evolution levels of the token
    Level[] public levels;

    struct TokenPoints {
        uint256 id;
        address owner;
        uint256 points;
    }

    // for easy lookup
    mapping(address => uint256) public tokenOf;

    // user messages (tokenId => message)
    mapping(uint256 => string) public messages;

    constructor(address tokenCollectionAddress, bytes memory baseImage) ERC721A("FriendshipCard", "FRIEND") {
        _setOwner(msg.sender);
        collectionAddress = tokenCollectionAddress;
        baseSvgPointer = SSTORE2.write(baseImage);

        levels.push(Level(0, "LEVEL 1", "#2EB4FF"));
        levels.push(Level(10, "LEVEL 2", "#FF5733"));
        levels.push(Level(50, "LEVEL 3", "#2EB4FF"));
        levels.push(Level(150, "LEVEL 4", "#2EB4FF"));
        levels.push(Level(500, "LEVEL 5", "#2EB4FF"));
        levels.push(Level(1500, "LEVEL 6", "#2EB4FF"));
        levels.push(Level(3500, "LEVEL 7", "#2EB4FF"));
        levels.push(Level(7500, "LEVEL 8", "#2EB4FF"));
    }

    function mintTo(address to) external onlyCollection {
        tokenOf[to] = _nextTokenId();
        _mint(to, 1);
    }

    function burnToken(uint256 tokenId) public {
        delete tokenOf[ownerOf(tokenId)];
        _burn(tokenId, true);
    }

    // set custom message for a token
    function setMessage(uint256 _tokenId, string calldata _message) public {
        if (ownerOf(_tokenId) != msg.sender) revert Unauthorized();
        if (bytes(_message).length > 256) revert MessageTooLong();

        messages[_tokenId] = _message;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        uint256 tokenPoints = points(tokenId);
        (string memory nameSuffix, string memory colorHex, uint256 levelCap) = levelData(tokenPoints);

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
                            tokenMessage(tokenId),
                            '",',
                            '"attributes":[{"trait_type":"points","max_value":',
                            _toString(levelCap),
                            ',"value":',
                            _toString(tokenPoints),
                            "}],",
                            '"image":"',
                            buildSvg(colorHex),
                            '"}'
                        )
                    )
                )
            )
        );
    }

    function tokenMessage(uint256 tokenId) public view returns (string memory) {
        string memory message = messages[tokenId];
        if (bytes(message).length > 0) {
            return message;
        } else {
            return DEFAULT_DESC;
        }
    }

    // construct image svg
    function buildSvg(string memory colorHex) internal view returns (string memory) {
        string memory baseUrl = "data:image/svg+xml;base64,";
        bytes memory baseSvg = SSTORE2.read(baseSvgPointer);

        return string(
            abi.encodePacked(
                baseUrl,
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '<svg viewBox="0 0 1080 1080" fill="none" xmlns="http://www.w3.org/2000/svg"><path fill="',
                            colorHex,
                            '" d=\"M0 0h1080v1080H0z"/>',
                            baseSvg,
                            "</svg>"
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
                    return (level.name, level.colorHex, nextLevel.minimum);
                } else {
                    // highest level
                    uint256 maxPoints = IERC721A(collectionAddress).totalSupply() * 2;
                    return (level.name, level.colorHex, maxPoints);
                }
            }
            unchecked {
                --i;
            }
        }
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
        if (from != address(0)) {
            if (to != from) {
                sentBitmap[from].setBatch(collectionTokenStartId, quantity);
            }
        }

        if (to != address(0)) {
            receivedBitmap[to].setBatch(collectionTokenStartId, quantity);
        }
    }

    // total points accumulated by a holder
    function points(uint256 tokenId) public view returns (uint256) {
        address owner = ownerOf(tokenId);
        uint256 max = IERC721A(collectionAddress).totalSupply() + 1;

        return receivedBitmap[owner].popCount(1, max) + sentBitmap[owner].popCount(1, max);
    }

    // get point information in a token range
    function tokenPointsInRange(uint256 startId, uint256 endId) public view returns (TokenPoints[] memory) {
        if (endId < startId) revert InvalidParams();

        TokenPoints[] memory tokenPoints = new TokenPoints[]((endId - startId) + 1);
        uint256 max = IERC721A(collectionAddress).totalSupply() + 1;

        uint256 pointsIndex;
        for (uint256 i = startId; i <= endId;) {
            if (_exists(i)) {
                address owner = ownerOf(i);
                uint256 totalPoints = receivedBitmap[owner].popCount(1, max) + sentBitmap[owner].popCount(1, max);

                tokenPoints[pointsIndex] = TokenPoints({id: i, owner: owner, points: totalPoints});
                ++pointsIndex;
            }
            ++i;
        }

        return tokenPoints;
    }

    // check if given address is a holder of the token
    function hasToken(address receiver) public view returns (bool) {
        return balanceOf(receiver) > 0;
    }

    // add a new evolution level to the list - must be greater points threshold than previous minimum
    function appendLevel(uint256 minimum, string calldata name, string calldata colorHex) external onlyOwner {
        Level memory lastLevel = levels[levels.length - 1];
        if (lastLevel.minimum >= minimum) revert LevelMinimumLowerThanExisting();

        levels.push(Level(minimum, name, colorHex));
    }

    // remove a level from the list
    function removeLevel(uint256 index) external onlyOwner {
        if (index >= levels.length) return;

        for (uint256 i = index; i < levels.length - 1;) {
            levels[i] = levels[i + 1];
            unchecked {
                ++i;
            }
        }

        levels.pop();
    }

    // check if given address has ever received tokenId
    function hasReceivedToken(address owner, uint256 tokenId) external view returns (bool) {
        return receivedBitmap[owner].get(tokenId);
    }

    // check if given address has ever sent tokenId
    function hasSentToken(address owner, uint256 tokenId) external view returns (bool) {
        return sentBitmap[owner].get(tokenId);
    }

    function tokenStatusMap(address owner, bool sent) external view returns (uint256[] memory received) {
        // TODO: reference max supply instead of hardcoding
        uint256 maxWordIndex = 5000 >> 8;
        uint256[] memory words = new uint256[](maxWordIndex + 1);
        for (uint256 i = 0; i <= maxWordIndex; i++) {
            words[i] = (sent ? sentBitmap[owner].map[i] : receivedBitmap[owner].map[i]);
        }
        return words;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    modifier onlyCollection() {
        if (msg.sender != collectionAddress) {
            revert Unauthorized();
        }
        _;
    }
}
