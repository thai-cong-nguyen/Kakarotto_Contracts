// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

import "./interfaces/IKakarottoTreasure.sol";
import "../NFTs/interfaces/IKakarottoItem.sol";
import "../libraries/NFTLibrary.sol";

// IKakarottoTreasure,
// IKakarottoTreasure,
contract KakarottoTreasure is
    IKakarottoTreasure,
    ERC1155,
    Ownable,
    ERC1155Burnable
{
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    uint256 public constant BRONZE = 0;
    uint256 public constant SILVER = 1;
    uint256 public constant GOLD = 2;
    uint256 public constant PLATINUM = 3;
    uint256 public constant DIAMOND = 4;
    uint256 public constant MAX_TOKEN_ID = 5;
    bytes32 public constant MINT_ACTION = bytes32("KAKAROTTO_MINT_TREASURE");
    bytes32 public constant OPEN_ACTION = bytes32("KAKAROTTO_OPEN_TREASURE");

    uint256 public tokenIdCounter;
    address public kakarottoItem;

    constructor(
        string memory _tokenURI,
        address _kakarottoItem,
        address _initialOwner
    ) ERC1155(_tokenURI) Ownable(_initialOwner) {
        kakarottoItem = _kakarottoItem;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
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

    // function
    function mint(
        address _creator,
        bytes memory _createNftSignature,
        uint256 _tokenId,
        uint256 _value,
        bytes memory data
    ) external onlyOwner {
        require(
            _tokenId >= 0 && _tokenId < MAX_TOKEN_ID,
            "Rarity must be greater than 0"
        );
        bytes32 dataHash = keccak256(
            abi.encodePacked(MINT_ACTION, _tokenId, _creator)
        );
        if (!verifySignature(_creator, dataHash, _createNftSignature)) {
            revert InvalidSignature();
        }
        _mint(_creator, _tokenId, _value, data);
    }

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
    ) external onlyOwner {
        bytes32 dataHash = keccak256(
            abi.encodePacked(OPEN_ACTION, _itemURI, _creator)
        );
        if (!verifySignature(_creator, dataHash, _createNftSignature)) {
            revert InvalidSignature();
        }

        emit OpenTreasure(_creator, _tokenId, _value);
        _burn(_creator, _tokenId, _value);
        IKakarottoItem(kakarottoItem).mint(
            _creator,
            _createNftSignature,
            _itemURI,
            _rarity,
            _attributeCount,
            _attributes,
            _values,
            _isIncreases,
            _isPercentss
        );
    }
}
