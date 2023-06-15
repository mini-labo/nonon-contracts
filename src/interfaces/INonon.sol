// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

import "ERC721A/IERC721A.sol";

interface INonon is IERC721A {
    function exists(uint256 _tokenId) external view returns (bool);
}
