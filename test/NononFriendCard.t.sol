// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../src/NononFriendCard.sol";
import "../src/Nonon.sol";

contract TestableFriendCard is NononFriendCard {
    constructor(address tokenAddress) NononFriendCard(tokenAddress) {}

    function getLevelData(uint256 tokenPoints) public view returns (NononFriendCard.LevelImageData memory) {
        return levelData(tokenPoints);
    }
}

contract NononFriendCardTest is Test {
    TestableFriendCard public friendshipCard;
    Nonon public nonon;

    function setUp() public {
        string memory baseSvgPath = "test/fixtures/base.svg";
        string memory defsSvgPath = "test/fixtures/defs.svg";
        string memory spritesPath = "test/fixtures/sprites.svg";
        nonon = new Nonon();

        friendshipCard = new TestableFriendCard(address(nonon));

        friendshipCard.setBaseSvgPointer(bytes(vm.readFile(baseSvgPath)));
        friendshipCard.setDefsSvgPointer(bytes(vm.readFile(defsSvgPath)));
        friendshipCard.setSpritesSvgPointer(bytes(vm.readFile(spritesPath)));

        nonon.setFriendshipCard(address(friendshipCard));
    }

    function testFailTransferToThirdParty() public {
        address recipient = vm.addr(999);
        vm.prank(address(nonon));
        friendshipCard.mintTo(recipient);

        vm.prank(recipient);
        friendshipCard.transferFrom(recipient, vm.addr(1), 1);
    }

    function testFailNonOwnerSetFriendshipCardAddress() public {
        address notAllowed = vm.addr(998);
        vm.prank(notAllowed);
        nonon.setFriendshipCard(notAllowed);
    }

    function testPointsMintingGrantsPointsCard() public {
        address newAddr = vm.addr(2);
        nonon.mint(newAddr, 1);
        assertEq(friendshipCard.balanceOf(newAddr), 1);
    }

    function testPointsMintingCardExistsNoNewCardMint() public {
        address newAddr = vm.addr(3);
        nonon.mint(newAddr, 1);
        nonon.mint(newAddr, 1);
        assertEq(friendshipCard.balanceOf(newAddr), 1);
    }

    function testPointsCalculation() public {
        address minter = vm.addr(4);
        address recipient = vm.addr(5);

        nonon.mint(minter, 1);

        // loyalty tokenId 1 - 1 point for receiving
        assertEq(friendshipCard.points(1), 1);

        vm.prank(minter);
        nonon.transferFrom(minter, recipient, 1);

        // loyalty tokenId 1 - 1 point each for sending, receiving
        assertEq(friendshipCard.points(1), 2);
        // loyalty tokenId 2 - should have been granted to recipeint and have
        // 1 point for receiving
        assertEq(friendshipCard.points(2), 1);
    }

    function testPointUniqueness() public {
        address minter = vm.addr(6);
        address recipient = vm.addr(7);

        nonon.mint(minter, 1);

        // loyalty tokenId 1 - 1 point for receiving
        assertEq(friendshipCard.points(1), 1);

        vm.prank(minter);
        nonon.transferFrom(minter, recipient, 1);

        vm.prank(recipient);
        nonon.transferFrom(recipient, minter, 1);

        // loyalty tokenId 1 - 1 point each for sending, receiving
        // does not count duplicate from receiving again!
        assertEq(friendshipCard.points(1), 2);
    }

    function testMultiMintPoints(uint16 quantity) public {
        vm.assume(quantity < 1000);
        vm.assume(quantity > 0);

        address minter = vm.addr(200);

        nonon.mint(minter, quantity);
        assertEq(friendshipCard.balanceOf(minter), 1);
        assertEq(friendshipCard.points(1), quantity);
    }

    function testSendToSelfNoPoints() public {
        address minter = vm.addr(201);
        nonon.mint(minter, 1);

        vm.prank(minter);
        nonon.transferFrom(minter, minter, 1);

        // just 1 point for receiving from mint
        assertEq(friendshipCard.points(1), 1);
    }

    function testBurnable() public {
        address minter = vm.addr(888);
        nonon.mint(minter, 1);
        assertEq(friendshipCard.balanceOf(minter), 1);

        vm.prank(minter);
        friendshipCard.burnToken(1);

        assertEq(friendshipCard.balanceOf(minter), 0);
    }

    function testFailNonHolderBurn() public {
        address minter = vm.addr(887);
        address evil = vm.addr(886);

        nonon.mint(minter, 1);
        assertEq(friendshipCard.balanceOf(minter), 1);

        vm.prank(evil);
        friendshipCard.burnToken(1);
    }

    function testLevelData() public {
        // 0 points, should be initial level
        // (string memory name,,,, uint256 cap) = friendshipCard.getLevelData(0);
        NononFriendCard.LevelImageData memory level = friendshipCard.getLevelData(0);
        // assertEq(name, "LEVEL 1");
        assertEq(level.suffix, "LEVEL 1");
        // should be minimum of index 1
        assertEq(level.cap, 10);

        // 14 points, should be index 1
        // (string memory name2,,,, uint256 cap2) = friendshipCard.getLevelData(14);
        NononFriendCard.LevelImageData memory level2 = friendshipCard.getLevelData(14);
        assertEq(level2.suffix, "LEVEL 2");
        assertEq(level2.cap, 50);

        // max level - should be cap value of 2x supply of underlying token collection
        // (string memory maxName,,,, uint256 maxCap) = friendshipCard.getLevelData(7501);

        NononFriendCard.LevelImageData memory level8 = friendshipCard.getLevelData(7501);
        assertEq(level8.suffix, "LEVEL 8");
        assertEq(level8.cap, nonon.totalSupply() * 2);
    }

    function testTokenPointsInRange() public {
        address minterOne = vm.addr(309);
        address minterTwo = vm.addr(310);
        address minterThree = vm.addr(311);

        nonon.mint(minterOne, 5);
        nonon.mint(minterTwo, 2);
        nonon.mint(minterThree, 1);

        NononFriendCard.TokenPoints[] memory allPoints = friendshipCard.tokenPointsInRange(1, 3);

        assertEq(allPoints[0].owner, minterOne);
        assertEq(allPoints[1].owner, minterTwo);
        assertEq(allPoints[2].owner, minterThree);

        assertEq(allPoints[0].points, 5);
        assertEq(allPoints[1].points, 2);
        assertEq(allPoints[2].points, 1);
    }

    function testTokenPointsInRangeMax() public {
        address minterOne = vm.addr(309);
        address minterTwo = vm.addr(310);
        address minterThree = vm.addr(311);

        nonon.mint(minterOne, 5);
        nonon.mint(minterTwo, 2);
        nonon.mint(minterThree, 1);

        for (uint256 i = 1; i < 2501; i++) {
            address newAddr = vm.addr(i);
            nonon.mint(newAddr, 1);
        }

        NononFriendCard.TokenPoints[] memory allPoints = friendshipCard.tokenPointsInRange(1, 100);

        assertEq(allPoints[0].owner, minterOne);
        assertEq(allPoints[1].owner, minterTwo);
        assertEq(allPoints[2].owner, minterThree);

        assertEq(allPoints[0].points, 6);
        assertEq(allPoints[1].points, 3);
        assertEq(allPoints[2].points, 2);
    }

    function testTokenPointsInRangeWorksIfIncludingBurned() public {
        address minterOne = vm.addr(319);
        address minterTwo = vm.addr(320);
        address minterThree = vm.addr(321);

        nonon.mint(minterOne, 5);
        nonon.mint(minterTwo, 2);
        nonon.mint(minterThree, 1);

        NononFriendCard.TokenPoints[] memory allPoints = friendshipCard.tokenPointsInRange(1, 3);

        assertEq(allPoints[0].owner, minterOne);
        assertEq(allPoints[1].owner, minterTwo);
        assertEq(allPoints[2].owner, minterThree);

        assertEq(allPoints[0].points, 5);
        assertEq(allPoints[1].points, 2);
        assertEq(allPoints[2].points, 1);

        vm.prank(minterTwo);
        friendshipCard.burnToken(2);

        NononFriendCard.TokenPoints[] memory newPoints = friendshipCard.tokenPointsInRange(1, 3);

        assertEq(newPoints[0].owner, minterOne);
        assertEq(newPoints[1].owner, minterThree);
        assertEq(newPoints[1].points, 1);
    }

    function testHasReceivedToken() public {
        address minter = vm.addr(300);
        nonon.mint(minter, 1);

        bool receivedFirst = friendshipCard.hasReceivedToken(minter, 1);
        bool receivedSecond = friendshipCard.hasReceivedToken(minter, 2);
        assertEq(receivedFirst, true);
        assertEq(receivedSecond, false);
    }

    function testGetReceivedTokens() public {
        address minter = vm.addr(300);
        nonon.mint(minter, 1);

        uint256[] memory tokenStatusWords = friendshipCard.tokenStatusMap(minter, false);
        uint256[] memory tokenStatusSentWords = friendshipCard.tokenStatusMap(minter, true);

        // 2nd bit of 1st word should be set (index 1 of word), but no others
        uint256 word = tokenStatusWords[0];
        bool tokenIndexIsSet = ((word & (1 << 1)) != 0);

        // sent flag should not be set for same bit
        uint256 sentWord = tokenStatusSentWords[0];
        bool tokenIndexSentIsSet = ((sentWord & (1 << 1)) != 0);

        assertEq(tokenIndexIsSet, true);
        assertEq(tokenIndexSentIsSet, false);

        for (uint256 i = 2; i <= 5000; i++) {
            uint256 targetWordIndex = i >> 8;
            uint256 bitIndex = i & 0xff;
            uint256 targetWord = tokenStatusWords[targetWordIndex];

            bool notReceivedTokenIsSet = ((targetWord & (1 << bitIndex)) != 0);
            assertEq(notReceivedTokenIsSet, false);
        }
    }

    function testGetReceivedTokensMaxSupply() public {
        address minter = vm.addr(300);
        nonon.mint(minter, 5000);

        uint256[] memory tokenStatusWords = friendshipCard.tokenStatusMap(minter, false);

        // all bits up to 5000 should be set
        for (uint256 i = 1; i <= 5000; i++) {
            uint256 targetWordIndex = i >> 8;
            uint256 bitIndex = i & 0xff;
            uint256 targetWord = tokenStatusWords[targetWordIndex];

            bool tokenIsSet = ((targetWord & (1 << bitIndex)) != 0);
            assertEq(tokenIsSet, true);
        }
    }

    function testGetSentTokens() public {
        address minter = vm.addr(300);
        address secondAddress = vm.addr(301);
        nonon.mint(minter, 1);

        vm.prank(minter);
        nonon.transferFrom(minter, secondAddress, 1);

        uint256[] memory tokenStatusSentWords = friendshipCard.tokenStatusMap(minter, true);

        // 2nd bit of 1st word should be set (index 1 of word), but no others
        uint256 word = tokenStatusSentWords[0];
        bool tokenIndexIsSet = ((word & (1 << 1)) != 0);

        assertEq(tokenIndexIsSet, true);

        for (uint256 i = 2; i <= 5000; i++) {
            uint256 targetWordIndex = i >> 8;
            uint256 bitIndex = i & 0xff;
            uint256 targetWord = tokenStatusSentWords[targetWordIndex];

            bool notReceivedTokenIsSet = ((targetWord & (1 << bitIndex)) != 0);
            assertEq(notReceivedTokenIsSet, false);
        }
    }

    function testGetSentTokensMaxSupply() public {
        address minter = vm.addr(300);
        address secondAddress = vm.addr(301);

        nonon.mint(minter, 5000);

        vm.startPrank(minter);
        for (uint256 i = 1; i <= 5000; i++) {
            nonon.transferFrom(minter, secondAddress, i);
        }

        uint256[] memory tokenStatusWords = friendshipCard.tokenStatusMap(minter, true);

        // all bits up to 5000 should be set
        for (uint256 i = 1; i <= 5000; i++) {
            uint256 targetWordIndex = i >> 8;
            uint256 bitIndex = i & 0xff;
            uint256 targetWord = tokenStatusWords[targetWordIndex];

            bool tokenIsSet = ((targetWord & (1 << bitIndex)) != 0);
            assertEq(tokenIsSet, true);
        }
    }
}
