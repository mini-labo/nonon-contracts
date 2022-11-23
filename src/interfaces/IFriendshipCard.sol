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

    /**
     * emitted when address of associated token collection is set
     */
    event CollectionAddressSet(address indexed caller, address indexed newCollectionAddress);

    function registerRecievedToken(address owner, uint256 collectionTokenId) external;

    function registerSentToken(address owner, uint256 collectionTokenId) external;

    function mintTo(address to) external;

    function hasToken(address receiver) external returns (bool);
}
