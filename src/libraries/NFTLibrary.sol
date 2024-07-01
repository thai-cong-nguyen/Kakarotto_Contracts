// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library NFTLibrary {
    enum Attribute {
        POWER,
        DEFEND,
        AGILITY,
        INTELLIGENCE,
        LUCK
    }
    struct NFTInformation {
        address nft;
        uint256 tokenId;
        address owner;
        uint256 initialPrice;
        uint256 startTime;
        uint256 endTime;
        uint256 highestBid;
        address highestBidder;
        bool feeNativeToken;
        address feeToken;
    }
    struct CharacterNftInformation {
        uint256 tokenId;
        uint256 rarity;
        uint256 power;
        uint256 defend;
        uint256 agility;
        uint256 intelligence;
        uint256 luck;
    }
    struct ItemNftInformation {
        uint256 tokenId;
        uint256 rarity;
        uint256 attributeCount;
        mapping(uint256 => ItemAttribute) attributes;
    }
    struct ItemAttribute {
        Attribute attribute;
        uint256 value;
        bool isIncrease;
        bool isPercent;
    }
}
