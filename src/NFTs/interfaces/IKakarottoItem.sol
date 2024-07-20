// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Burnable.sol";

import "../../libraries/NFTLibrary.sol";

interface IKakarottoItem {
    error InvalidSignature();
    event ItemCreated(
        uint256 indexed tokenId,
        address indexed receiver,
        string tokenURI
    );

    function mint(
        address _creator,
        bytes memory _createNftSignature,
        string memory _tokenURI,
        uint256 _rarity,
        uint256 _attributeCount,
        NFTLibrary.Attribute[] memory _attributes,
        uint256[] memory _values,
        bool[] memory _isIncreases,
        bool[] memory _isPercentss
    ) external returns (uint256);
}
