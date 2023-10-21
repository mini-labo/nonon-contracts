// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

import "forge-std/Script.sol";
import "../src/Nonon.sol";
import "../src/NononFriendCard.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPK = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPK);

        Nonon nonon = new Nonon();
        NononFriendCard friendshipCard = new NononFriendCard(address(nonon));
        nonon.setFriendshipCard(address(friendshipCard));

        friendshipCard.setBaseSvgPointer(bytes(vm.readFile("test/fixtures/base.svg")));
        friendshipCard.setDefsSvgPointer(bytes(vm.readFile("test/fixtures/defs.svg")));
        friendshipCard.setSpritesSvgPointer(bytes(vm.readFile("test/fixtures/sprites.svg")));

        vm.stopBroadcast();
    }
}
