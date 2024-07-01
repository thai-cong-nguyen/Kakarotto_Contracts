// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Clock {
    // Clock
    function clock() public view returns (uint48) {
        return uint48(block.timestamp);
    }
}
