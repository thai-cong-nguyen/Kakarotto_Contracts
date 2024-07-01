// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library UserLibrary {
    struct UserInformation {
        uint256 userId;
        address userAddress;
        uint256 userJoinedAt;
        uint256 userUpdated;
    }
}
