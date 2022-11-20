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
}
