// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library MarketplaceLibrary {
    struct Order {
        bytes32 id;
        address seller;
        address nftAddress;
        uint256 priceInWei;
        uint256 expiresAt;
    }
}
