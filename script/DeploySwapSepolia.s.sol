// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

import "forge-std/Script.sol";
import "../src/NononSwap.sol";


contract DeployScript is Script {
    address constant nonon = address(0x42c384e1D804C2d6A2D7b3002ea416E1d8cB24fE);

    function run() external {
        uint256 deployerPK = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPK);

        NononSwap nononSwap = new NononSwap(nonon);
    }
}
