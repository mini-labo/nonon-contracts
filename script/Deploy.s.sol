// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Nonon.sol";
import "../src/FriendshipCard.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPK = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPK);

        FriendshipCard friendshipCard = new FriendshipCard();
        Nonon nonon = new Nonon(address(friendshipCard));
        friendshipCard.setCollectionAddress(address(nonon));

        vm.stopBroadcast();
    }
}
