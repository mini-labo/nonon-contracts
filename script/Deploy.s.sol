// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

import "forge-std/Script.sol";
import "../src/Nonon.sol";
import "../src/FriendshipCard.sol";
import "../src/NononSwap.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPK = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPK);

        Nonon nonon = new Nonon();
        FriendshipCard friendshipCard = new FriendshipCard(address(nonon), bytes(vm.readFile("test/fixtures/base.svg")));
        nonon.setFriendshipCard(address(friendshipCard));

        vm.stopBroadcast();
    }
}
