// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKakarottoCharacter {
    // Error
    error InvalidSignature();
    error CharacterCreatedFailed();
    error CharacterLevelUpFailed();
    // Event
    event KakarottoCharacterCreated(
        uint256 tokenId,
        string tokenUri,
        address owner,
        address indexed account
    );
    event KakarottoCharacterLevelUp(
        uint256 indexed tokenId,
        uint256 fromLevel,
        uint256 toLevel
    );

    function createNFT(
        string memory _tokenURI,
        address _creator,
        bytes memory _createNftSignature,
        uint256 rarity,
        uint256 power,
        uint256 defend,
        uint256 agility,
        uint256 intelligence,
        uint256 luck
    ) external returns (address _account);

    function levelUp(
        uint256 _tokenId,
        address _creator,
        bytes memory _levelUpNftSignature
    ) external returns (uint256 level);
}
