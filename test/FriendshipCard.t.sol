// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../src/FriendshipCard.sol";
import "../src/Nonon.sol";

contract FriendshipCardTest is Test {
    FriendshipCard public friendshipCard;
    Nonon public nonon;

    function setUp() public {
        friendshipCard = new FriendshipCard();
        nonon = new Nonon(address(friendshipCard));

        friendshipCard.setCollectionAddress(address(nonon));
    }

    function testFailTransferToThirdParty() public {
        address recipient = vm.addr(999);
        vm.prank(address(nonon));
        friendshipCard.mintTo(recipient);
        vm.stopPrank();

        vm.prank(recipient);
        friendshipCard.transferFrom(recipient, vm.addr(1), 0);
    }

    function testFailNonOwnerSetCollectionAddress() public {
        address notAllowed = vm.addr(998);
        vm.prank(notAllowed);
        friendshipCard.setCollectionAddress(notAllowed);
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

        // loyalty tokenId 0 - 1 point for receiving
        assertEq(friendshipCard.points(0), 1);

        vm.prank(minter);
        nonon.transferFrom(minter, recipient, 0);
        vm.stopPrank();

        // loyalty tokenId 0 - 1 point each for sending, receiving
        assertEq(friendshipCard.points(0), 2);
        // loyalty tokenId 1 - should have been granted to recipeint and have
        // 1 point for receiving
        assertEq(friendshipCard.points(1), 1);
    }

    function testPointUniqueness() public {
        address minter = vm.addr(6);
        address recipient = vm.addr(7);

        nonon.mint(minter, 1);

        // loyalty tokenId 0 - 1 point for receiving
        assertEq(friendshipCard.points(0), 1);

        vm.prank(minter);
        nonon.transferFrom(minter, recipient, 0);
        vm.stopPrank();

        vm.prank(recipient);
        nonon.transferFrom(recipient, minter, 0);
        vm.stopPrank();

        // loyalty tokenId 0 - 1 point each for sending, receiving
        // does not count duplicate from receiving again!
        assertEq(friendshipCard.points(0), 2);
    }

    function testMultiMintPoints(uint16 quantity) public {
        vm.assume(quantity < 1000);
        vm.assume(quantity > 0);

        address minter = vm.addr(200);

        nonon.mint(minter, quantity);
        assertEq(friendshipCard.balanceOf(minter), 1);
        assertEq(friendshipCard.points(0), quantity);
    }

    function testBurnable() public {
        address minter = vm.addr(888);
        nonon.mint(minter, 1);
        assertEq(friendshipCard.balanceOf(minter), 1);

        vm.prank(minter);
        friendshipCard.burnToken(0);
        vm.stopPrank();

        assertEq(friendshipCard.balanceOf(minter), 0);
    }

    function testFailNonHolderBurn() public {
        address minter = vm.addr(887);
        address evil = vm.addr(886);

        nonon.mint(minter, 1);
        assertEq(friendshipCard.balanceOf(minter), 1);

        vm.prank(evil);
        friendshipCard.burnToken(0);
    }

    function testAppendLevel() public {
        friendshipCard.appendLevel(10, "level 2", "https://example.com/image");

        // index 0 inserted by constructor
        (uint16 minimum, string memory name, string memory imageURI) = friendshipCard.levels(1);

        assertEq(minimum, 10);
        assertEq(name, "level 2");
        assertEq(imageURI, "https://example.com/image");
    }

    function testFailAppendLevelAsNonOwner() public {
        address evil = vm.addr(800);
        vm.prank(evil);
        friendshipCard.appendLevel(10, "level 2", "https://example.com/image");
    }

    function testFailAppendLevelBelowExistingMinimumPoints() public {
        // constructor inserts minimum of 0
        friendshipCard.appendLevel(0, "level 2", "https://example.com/image");
    }

    function testRemoveLevel() public {
        // insert index 1 and 2
        friendshipCard.appendLevel(10, "level 2", "https://example.com/image");
        friendshipCard.appendLevel(20, "level 3", "https://example.com/image");

        // remove index 1
        friendshipCard.removeLevel(1);

        // previous index 2 should be new index 1
        (uint16 minimum, string memory name, string memory imageURI) = friendshipCard.levels(1);

        assertEq(minimum, 20);
        assertEq(name, "level 3");
        assertEq(imageURI, "https://example.com/image");
    }
}
