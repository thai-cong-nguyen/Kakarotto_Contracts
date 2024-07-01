// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AuctionLibrary {
    struct Bid {
        uint256 id;
        address bidder;
        address tokenAddress;
        uint256 tokenId;
        uint256 price;
        uint256 expiresAt;
    }
    struct AuctionInformation {
        uint256 id;
        address auctioneer;
        address vault;
        address tokenAddress;
        uint256 tokenId;
        uint256 createdTime;
        uint256 startTime;
        uint256 endTime;
    }
}
