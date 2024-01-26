pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../src/Nonon.sol";
import "../src/NononFriendCard.sol";
import "../src/NononSwap.sol";

contract TestableFriendshipCard is NononFriendCard {
    constructor(address tokenAddress) NononFriendCard(tokenAddress) {}

    function getLevelData(uint256 tokenPoints) public view returns (NononFriendCard.LevelImageData memory) {
        return levelData(tokenPoints);
    }
}

contract NononSwapTest is Test {
    TestableFriendshipCard public friendshipCard;
    Nonon public nonon;
    NononSwap public nononSwap;

    function setUp() public {
        nonon = new Nonon();
        friendshipCard = new TestableFriendshipCard(address(nonon));
        nonon.setFriendshipCard(address(friendshipCard));

        nononSwap = new NononSwap(address(nonon));
    }

    function testCreateOpenOffer() public {
        address a = vm.addr(1);

        nonon.mint(a, 1);

        vm.startPrank(a);
        nonon.setApprovalForAll(address(nononSwap), true);
        nononSwap.createTokenOffer(1, 0); // open offer
        vm.stopPrank();
    }

    function testCantCreateMultipleOffersSameToken() public {
        address a = vm.addr(1);

        nonon.mint(a, 1);

        vm.startPrank(a);

        nonon.setApprovalForAll(address(nononSwap), true);
        nononSwap.createTokenOffer(1, 0);

        vm.expectRevert(TokenHasExistingOffer.selector);
        nononSwap.createTokenOffer(1, 0);

        vm.stopPrank();
    }

    function testCantCreateOfferNotOwnedToken() public {
        address a = vm.addr(1);
        address b = vm.addr(2);

        nonon.mint(a, 1);
        nonon.mint(b, 2);

        vm.startPrank(a);

        vm.expectRevert(Unauthorized.selector);
        nononSwap.createTokenOffer(3, 0);

        vm.stopPrank();
    }

    function testCantCreateOfferNonExistentToken() public {
        address a = vm.addr(1);

        nonon.mint(a, 1);

        vm.startPrank(a);

        vm.expectRevert(OfferForNonexistentToken.selector);
        nononSwap.createTokenOffer(3, 0);

        vm.stopPrank();
    }

    function testCantCompleteNonExistentOffer() public {
        address a = vm.addr(1);
        address b = vm.addr(2);

        nonon.mint(a, 1);
        nonon.mint(b, 2);

        vm.startPrank(b);

        vm.expectRevert(NoActiveOffer.selector);
        nononSwap.completeTokenOffer(1, 3);

        vm.stopPrank();
    }

    function testCanSwapNononOpenId() public {
        address a = vm.addr(1);
        address b = vm.addr(2);

        nonon.mint(a, 1);
        nonon.mint(b, 1);

        vm.startPrank(a);
        nonon.setApprovalForAll(address(nononSwap), true);
        nononSwap.createTokenOffer(1, 0); // open offer
        vm.stopPrank();

        vm.startPrank(b);
        nonon.setApprovalForAll(address(nononSwap), true);
        nononSwap.completeTokenOffer(1, 2);
        vm.stopPrank();

        // both users retain total balance of 1 token
        assertEq(nonon.balanceOf(a), 1);
        assertEq(nonon.balanceOf(b), 1);

        // user a has token 2, user b has token 1
        assertEq(nonon.ownerOf(2), a);
        assertEq(nonon.ownerOf(1), b);
    }

    function testCanSwapTargetedId() public {
        address a = vm.addr(1);
        address b = vm.addr(2);

        // mint 5 tokens each
        nonon.mint(a, 5);
        nonon.mint(b, 5);

        vm.startPrank(a);
        nonon.approve(address(nononSwap), 1);
        nononSwap.createTokenOffer(1, 8); // offer token 1 for token 8
        vm.stopPrank();

        vm.startPrank(b);
        nonon.approve(address(nononSwap), 8);
        nononSwap.completeTokenOffer(1, 8); // complete offer by exchanging token 8
        vm.stopPrank();

        // both users retain total balance of 5 tokens
        assertEq(nonon.balanceOf(a), 5);
        assertEq(nonon.balanceOf(b), 5);

        // user a has token 8, user b has token 1
        assertEq(nonon.ownerOf(8), a);
        assertEq(nonon.ownerOf(1), b);
    }

    function testRemoveOffer() public {
        address a = vm.addr(1);

        nonon.mint(a, 5);

        vm.startPrank(a);
        nonon.approve(address(nononSwap), 1);
        nonon.approve(address(nononSwap), 2);
        nononSwap.createTokenOffer(1, 0);
        nononSwap.createTokenOffer(2, 0);
        nononSwap.createTokenOffer(3, 0);

        nononSwap.removeOffer(2);
        vm.stopPrank();

        assertEq(nononSwap.getAllAvailableOffers().length, 2);
        assertEq(nononSwap.getAllAvailableOffers()[0].ownedId, 1);
        assertEq(nononSwap.getAllAvailableOffers()[1].ownedId, 3);
    }

    function testGetAvailableOffersByToken() public {
        address a = vm.addr(1);
        address b = vm.addr(2);

        nonon.mint(a, 5);
        nonon.mint(b, 5);

        vm.startPrank(a);
        nonon.approve(address(nononSwap), 1);
        nonon.approve(address(nononSwap), 2);
        nonon.approve(address(nononSwap), 3);
        nonon.approve(address(nononSwap), 4);
        nononSwap.createTokenOffer(1, 6);
        nononSwap.createTokenOffer(2, 6);
        nononSwap.createTokenOffer(3, 6);
        nononSwap.createTokenOffer(4, 7);
        vm.stopPrank();

        assertEq(nononSwap.getAvailableOffersByToken(6).length, 3);
        assertEq(nononSwap.getAvailableOffersByToken(7).length, 1);

        assertEq(nononSwap.getAvailableOffersByToken(7)[0].owner, a);
        assertEq(nononSwap.getAvailableOffersByToken(7)[0].ownedId, 4);
        assertEq(nononSwap.getAvailableOffersByToken(7)[0].wantedId, 7);
    }
}
