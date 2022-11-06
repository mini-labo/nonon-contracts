// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.13;

interface ILoyaltyCard {
    function registerRecievedToken(address owner, uint256 collectionTokenId) external;

    function registerSentToken(address owner, uint256 collectionTokenId) external;

    function mintTo(address to) external;

    function balanceOf(address owner) external view returns (uint256);
}
