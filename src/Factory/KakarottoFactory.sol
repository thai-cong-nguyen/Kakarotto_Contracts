// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

import "./IKakarottoFactory.sol";
import "../NFTs/interfaces/IKakarottoCharacter.sol";
import "../NFTs/interfaces/IKakarottoItem.sol";
import "../libraries/NFTLibrary.sol";

contract KakarottoFactory is IFactory, Ownable, Pausable, ReentrancyGuard {
    // mapping(address => uint256) public nftsCount;
    // @dev creatorAddress => nftId => nftAddress
    // mapping(address => mapping(uint256 => address)) public nftAddresses;

    // Fee protocol
    address public fee;
    address public feeSetter;

    event NFTCreated(address indexed _nftOwner, address indexed _nftAddress);

    modifier onlyFeeSetter() {
        require(
            msg.sender == feeSetter,
            "Permission: Only fee setter can call this function"
        );
        _;
    }

    constructor() Ownable(msg.sender) Pausable() {}

    function createNFTs(
        string memory _tokenURI,
        uint256 _treasureId,
        address _creator,
        bytes memory _createNftSignature,
        bool isCharacter,
        uint256 fee,
        uint256 rarity,
        uint256 power,
        uint256 defend,
        uint256 agility,
        uint256 intelligence,
        uint256 luck
    ) external override nonReentrant whenNotPaused returns (address _account) {
        if (fee > 0) {
            // Transfer fee
        }
        // Create NFTs
        if (isCharacter) {
            return
                _createCharacter(
                    _tokenURI,
                    _creator,
                    _createNftSignature,
                    rarity,
                    power,
                    defend,
                    agility,
                    intelligence,
                    luck
                );
        }
        return
            _createItem(
                _tokenURI,
                _creator,
                _createNftSignature,
                rarity,
                power,
                defend,
                agility,
                intelligence,
                luck
            );
    }

    function _createCharacter(
        string memory _tokenURI,
        address _creator,
        bytes memory _createNftSignature,
        uint256 rarity,
        uint256 power,
        uint256 defend,
        uint256 agility,
        uint256 intelligence,
        uint256 luck
    ) internal returns (address _account) {}

    function _createItem(
        string memory _tokenURI,
        address _creator,
        uint256 rarity,
        uint256 _attributeCount
    ) internal returns (address _address) {}

    // Setter & Getter
    function setFeeSetter(address _feeSetter) external onlyOwner {
        feeSetter = _feeSetter;
    }

    function setFeeAddress(address _fee) external onlyFeeSetter {
        fee = _fee;
    }

    receive() external payable {}

    fallback() external payable {}
}
