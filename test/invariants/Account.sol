// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Account {
    function proxy(address target, bytes memory _calldata) external returns (bytes memory) {
        (bool success, bytes memory returnData) = address(target).call(_calldata);
        require(success);
        return returnData;
    }

    function pay(address target, bytes memory _calldata, uint256 value) external returns (bytes memory) {
        require(address(this).balance >= value);
        (bool success, bytes memory returnData) = payable(target).call{value: value}(_calldata);
        require(success);
        return returnData;
    }
}

