// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

import "../Gaming/interfaces/IERC6551Registry.sol";
import "./interfaces/IKakarottoCharacter.sol";
import "../libraries/NFTLibrary.sol";

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
    bytes32 public constant LEVELUP_ACTION = keccak256("KAKAROTTO_LEVELUP");
    uint256 public constant MAX_LEVEL = 20;
    uint256 public constant BASE_EXP = 100;
    uint256 public constant PRECISION = 1e18;

    IERC6551Registry public accountRegistry;
    uint256 public tokenIdCounter;
    address public battle;
    address public factory;

    mapping(address => bool) private accounts;
    // tokenId => level
    mapping(uint256 => uint256) private characterLevels;
    mapping(uint256 => uint256) private characterExps;
    mapping(uint256 => NFTLibrary.CharacterNftInformation)
        private characterInformations;

    constructor(
        string memory _name,
        string memory _symbol,
        address _initialOwner,
        IERC6551Registry _accountRegistry,
        address _battle,
        address _factory
    ) ERC721(_name, _symbol) Ownable(_initialOwner) {
        battle = _battle;
        factory = _factory;
        accountRegistry = _accountRegistry;
    }

    modifier onlyBattleOrFactory() {
        require(
            msg.sender == owner() ||
                msg.sender == battle ||
                msg.sender == factory,
            "KakarottoCharacter: Not the owner or battle contract"
        );
        _;
    }

    modifier onlyBattle() {
        require(
            msg.sender == battle || msg.sender == owner(),
            "KakarottoCharacter: Not the battle contract"
        );
        _;
    }

    modifier onlyFactory() {
        require(
            msg.sender == factory || msg.sender == owner(),
            "KakarottoCharacter: Not the factory contract"
        );
        _;
    }

    modifier notZeroAmount(uint256 value) {
        require(value > 0, "KakarottoCharacter: Zero amount");
        _;
    }

    modifier notZeroAddress(address _address) {
        require(_address != address(0), "KakarottoCharacter: Zero address");
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
    ) external onlyFactory returns (address _account) {
        bytes32 dataHash = keccak256(
            abi.encodePacked(MINT_ACTION, _tokenURI, _creator)
        );
        if (!verifySignature(_creator, dataHash, _createNftSignature)) {
            revert InvalidSignature();
        }

        uint256 _tokenIdCounter = tokenIdCounter;
        _safeMint(_creator, _tokenIdCounter);
        _setTokenURI(_tokenIdCounter, _tokenURI);

        _account = accountRegistry.createAccount(
            address(0),
            0,
            block.chainid,
            address(this),
            _tokenIdCounter,
            bytes("")
        );

        NFTLibrary.CharacterNftInformation memory _information = NFTLibrary
            .CharacterNftInformation(
                _tokenIdCounter,
                rarity,
                power,
                defend,
                agility,
                intelligence,
                luck
            );
        characterInformations[_tokenIdCounter] = _information;
        characterLevels[_tokenIdCounter] = 1;
        characterExps[_tokenIdCounter] = 0;
        if (
            characterInformations[tokenIdCounter++].tokenId != _tokenIdCounter
        ) {
            revert CharacterCreatedFailed();
        }

        emit KakarottoCharacterCreated(
            _tokenIdCounter,
            _tokenURI,
            _creator,
            _account
        );
    }

    function levelUp(
        uint256 _tokenId,
        address _creator,
        bytes memory _levelUpNftSignature
    ) external onlyOwner returns (uint256 level) {
        address nftOwner = ownerOf(_tokenId);
        require(nftOwner == _creator, "KakarottoCharacter: Not the owner");
        bytes32 dataHash = keccak256(
            abi.encodePacked(LEVELUP_ACTION, _tokenId, _creator)
        );
        if (!verifySignature(_creator, dataHash, _levelUpNftSignature)) {
            revert InvalidSignature();
        }

        // memory variables
        uint256 _exp = characterExps[_tokenId];
        uint256 _level = characterLevels[_tokenId];
        uint256 _expNeeded = BASE_EXP * (_level + 1);

        if (_level < 0 || _level >= MAX_LEVEL || _exp < _expNeeded) {
            revert CharacterLevelUpFailed();
        }

        // Increase stats
        NFTLibrary.CharacterNftInformation storage char = characterInformations[
            _tokenId
        ];
        char.power += 1;
        char.defend += 1;
        char.agility += 1;
        char.intelligence += 1;
        char.luck += 1;
        _level++;
        characterLevels[_tokenId] = _level;

        emit KakarottoCharacterLevelUp(_tokenId, _level - 1, _level);
        return _level + 1;
    }

    function increaseExp(
        uint256 _tokenId,
        uint256 _value
    ) external onlyBattle returns (uint256 characterExp) {
        require(
            _tokenId >= 0 && _tokenId < tokenIdCounter,
            "KakarottoCharacter: Invalid tokenId"
        );
        uint256 _exp = characterExps[_tokenId] + _value;

        characterExps[_tokenId] = _exp;
        characterExp = _exp;
    }

    function getCharacterInfo(
        uint256 _tokenId
    ) external view returns (NFTLibrary.CharacterNftInformation memory) {
        // _requireOwned(_tokenId);
        return characterInformations[_tokenId];
    }

    function getCharacterLevel(
        uint256 _tokenId
    ) external view returns (uint256) {
        // _requireOwned(_tokenId);
        return characterLevels[_tokenId];
    }

    function getCharacterExp(uint256 _tokenId) external view returns (uint256) {
        // _requireOwned(_tokenId);
        return characterExps[_tokenId];
    }
}
