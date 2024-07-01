// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import "../Gaming/interfaces/IERC6551Registry.sol";
import "../Gaming/interfaces/IRelationshipRegistry.sol";
import "../libraries/NFTLibrary.sol";
import "./interfaces/IKakarottoCharacter.sol";

contract KakarottoCharacter is
    ERC721,
    ERC721URIStorage,
    Ownable,
    ERC721Burnable,
    IKakarottoCharacter
{
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    bytes32 public constant MINT_ACTION = keccak256("KAKAROTTO_MINT");
    uint256 public constant MAX_LEVEL = 20;
    uint256 public constant BASE_EXP = 100;
    uint256 public constant PRECISION = 1e18;

    IRelationshipRegistry public relationshipRegistry;
    IERC6551Registry public accountRegistry;
    uint256 public tokenIdCounter;
    address public token;

    mapping(address => bool) public accounts;
    mapping(uint256 => uint256) public characterLevels;
    mapping(uint256 => uint256) public characterExps;
    mapping(uint256 => NFTLibrary.CharacterNftInformation)
        public characterInformations;

    constructor(
        string memory _name,
        string memory _symbol,
        address _initialOwner,
        address _relationshipRegistry,
        IERC6551Registry _accountRegistry,
        address _token
    ) ERC721(_name, _symbol) Ownable(_initialOwner) {
        token = _token;
        tokenIdCounter = 0;
        relationshipRegistry = _relationshipRegistry;
        accountRegistry = _accountRegistry;
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
        address _creator,
        bytes32 memory _dataHash,
        bytes memory _signature
    ) public pure returns (bool) {
        return recoverSigner(_dataHash, _signature) == _creator;
    }

    function recoverSigner(
        bytes32 memory _dataHash,
        bytes memory _signature
    ) public pure returns (address) {
        return dataHash.toEthSignedMessageHash().recover(_signature);
    }

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
    ) external onlyOwner returns (address _account) {
        bytes32 dataHash = keccak256(
            abi.encodePacked(MINT_ACTION, _tokenURI, _creator)
        );
        if (!verifySignature(_creator, dataHash, _createNftSignature)) {
            revert InvalidSignature();
        }

        uint256 _tokenIdCounter = tokenIdCounter;
        _safeMint(_creator, _tokenIdCounter);
        _setTokenURI(_tokenIdCounter, _tokenURI);

        _account = accountRegistry.createAccount{value: 0}(
            address(0),
            0,
            block.chainid,
            address(this),
            _tokenIdCounter,
            bytes("")
        );

        NFTLibrary.CharacterNftInformation _information = new NFTLibrary.CharacterNftInformation(
                _tokenIdCounter,
                rarity,
                power,
                defend,
                agility,
                intelligence,
                luck
            );
        characterInformations[_tokenIdCounter] = _information;
        if (characterInformations[_tokenIdCounter].tokenId != _tokenIdCounter) {
            revert CharacterCreatedFailed();
        }

        emit KakarottoCharacterCreated(
            _tokenIdCounter,
            _tokenURI,
            _creator,
            _account
        );
        _tokenIdCounter++;
    }

    function levelUp(
        uint256 _tokenId,
        uint256 _point
    ) external onlyOwner returns (uint256 level) {
        uint256 _exp = characterExps[_tokenId];
        uint256 _level = characterLevels[_tokenId];

        // max level => stop increasing level
        if (_level >= MAX_LEVEL) {
            return _level;
        }

        uint256 _expNeeded = BASE_EXP * (_level + 1);

        uint256 _newExp = _exp + _point;

        if (_newExp >= _expNeeded) {
            _level++;
            _newExp = _newExp - _expNeeded;
        }

        if (_level < 0 || _level > MAX_LEVEL) {
            revert CharacterLevelUpFailed();
        }

        characterLevels[_tokenId] = _level;
        characterExps[_tokenId] = _newExp;

        emit KakarottoCharacterLevelUp(_tokenId, _level - 1, _level);
        return _level;
    }
}
