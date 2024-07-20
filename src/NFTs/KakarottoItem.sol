// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

import "../libraries/NFTLibrary.sol";
import "../NFTs/interfaces/IKakarottoItem.sol";

contract KakarottoItem is
    ERC721,
    ERC721URIStorage,
    Ownable,
    ERC721Burnable,
    IKakarottoItem
{
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    bytes32 public constant MINT_ACTION = keccak256("KAKAROTTO_ITEM_MINT");
    uint8 public constant MIN_ATTRIBUTE_COUNT = 5;
    uint8 public constant MAX_ATTRIBUTE_COUNT = 5;

    uint256 public tokenIdCounter;
    address public treasure;

    mapping(uint256 => NFTLibrary.ItemNftInformation) private itemInformations;

    constructor(
        address _initialOwner,
        address _treasure,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) Ownable(_initialOwner) {
        treasure = _treasure;
    }

    modifier onlyTreasureOrOwner() {
        require(
            msg.sender == treasure || msg.sender == owner(),
            "KakarottoItem: caller is not the treasure or owner"
        );
        _;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function verifySignature(
        // creator of Signature
        address _creator,
        bytes32 _dataHash,
        bytes memory _signature
    ) public pure returns (bool) {
        return recoverSigner(_dataHash, _signature) == _creator;
    }

    function recoverSigner(
        bytes32 _dataHash,
        bytes memory _signature
    ) public pure returns (address) {
        return _dataHash.toEthSignedMessageHash().recover(_signature);
    }

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
    ) external onlyTreasureOrOwner returns (uint256) {
        require(
            _attributeCount >= MIN_ATTRIBUTE_COUNT &&
                _attributeCount <= MAX_ATTRIBUTE_COUNT,
            "KakarottoItem: attribute count exceeds maximum"
        );
        require(
            _attributes.length == _attributeCount &&
                _values.length == _attributeCount &&
                _isIncreases.length == _attributeCount &&
                _isPercentss.length == _attributeCount,
            "KakarottoItem: invalid attribute information"
        );
        bytes32 dataHash = keccak256(
            abi.encodePacked(MINT_ACTION, _tokenURI, _creator)
        );
        if (!verifySignature(_creator, dataHash, _createNftSignature)) {
            revert InvalidSignature();
        }
        
        uint256 _tokenId = tokenIdCounter;
        NFTLibrary.ItemNftInformation
            memory _itemInformation = itemInformations[_tokenId];
        require(
            _itemInformation.attributeCount == 0,
            "KakarottoItem: item already minted"
        );
        require(
            _itemInformation.attributes.length == 0,
            "KakarottoItem: item already minted"
        );
        NFTLibrary.ItemNftInformation
            storage itemInformation = itemInformations[_tokenId];

        itemInformation.tokenId = _tokenId;
        itemInformation.rarity = _rarity;
        itemInformation.attributeCount = _attributeCount;
        for (uint256 i = 0; i < _attributeCount; i++) {
            itemInformation.attributes.push(
                NFTLibrary.ItemAttribute({
                    attribute: _attributes[i],
                    value: _values[i],
                    isIncrease: _isIncreases[i],
                    isPercent: _isPercentss[i]
                })
            );
        }

        _safeMint(_creator, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
        emit ItemCreated(_tokenId, _creator, tokenURI(_tokenId));

        return _tokenId;
    }
}
