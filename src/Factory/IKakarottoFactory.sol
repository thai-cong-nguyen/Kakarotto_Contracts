// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../libraries/NFTLibrary.sol";

interface IFactory {
    event NFTCreated(address indexed _nftOwner, address indexed _nftAddress);
    function createCharacter(
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

    function createTreasure(
        address _creator,
        bytes memory _createNftSignature,
        uint256 _tokenId,
        uint256 _value,
        bytes memory data
    ) external;

    function createItem(
        address _creator,
        bytes memory _createNftSignature,
        uint256 _tokenId,
        string memory _itemURI,
        uint256 _value,
        uint256 _rarity,
        uint256 _attributeCount,
        NFTLibrary.Attribute[] memory _attributes,
        uint256[] memory _values,
        bool[] memory _isIncreases,
        bool[] memory _isPercentss
    ) external;

    function chargeFee(uint256 _fee) external;
}
