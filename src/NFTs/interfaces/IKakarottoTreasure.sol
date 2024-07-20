// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../../libraries/NFTLibrary.sol";

interface IKakarottoTreasure {
    // error
    error InvalidSignature();
    // event
    event OpenTreasure(
        address indexed _creator,
        uint256 _tokenId,
        uint256 _value
    );
    // function
    function mint(
        address _creator,
        bytes memory _createNftSignature,
        uint256 _tokenId,
        uint256 _value,
        bytes memory data
    ) external;
    function openTreasure(
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
}
