// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../src/LoyaltyCard.sol";

contract LoyaltyCardTest is Test {
    LoyaltyCard public loyaltyCard;

    function setUp() public {
        loyaltyCard = new LoyaltyCard();
        Vm vm = Vm(HEVM_ADDRESS);
    }

    function testMint() public {
        assertEq(loyaltyCard.balanceOf(address(this)), 1);
    }

    function testFailTransferToThirdParty() public {
        loyaltyCard.transferFrom(address(this), vm.addr(1), 1);
    }
}
