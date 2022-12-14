// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.16;

interface IFriendshipCard {
    /**
     * cannot transfer the soulbound token
     */
    error OnlyForYou();

    /**
     * cannot set collection address to zero address
     */
    error CollectionZeroAddress();

    /**
     * cannot add new level with a lower minimum
     */
    error LevelMinimumLowerThanExisting();

    function registerTokenMovement(address from, address to, uint256 collectionTokenStartId, uint256 quantity)
        external;

    function mintTo(address to) external;

    function hasToken(address receiver) external returns (bool);
}
