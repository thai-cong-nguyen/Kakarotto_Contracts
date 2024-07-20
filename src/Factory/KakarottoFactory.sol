// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "lib/openzeppelin-contracts/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import "./IKakarottoFactory.sol";
import "../NFTs/interfaces/IKakarottoCharacter.sol";
import "../NFTs/interfaces/IKakarottoItem.sol";
import "../NFTs/interfaces/IKakarottoTreasure.sol";
import "../libraries/NFTLibrary.sol";

contract KakarottoFactory is IFactory, Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public characterNFT;
    address public itemNFT;
    address public treasureNFT;
    // Fee protocol
    address public feeToken;
    address public fee;
    address public feeSetter;

    modifier onlyFeeSetter() {
        require(
            msg.sender == feeSetter || msg.sender == owner(),
            "Permission: Only fee setter can call this function"
        );
        _;
    }

    constructor(
        address _characterNFT,
        address _itemNFT,
        address _treasureNFT,
        address _feeToken
    ) Ownable(msg.sender) Pausable() {
        characterNFT = _characterNFT;
        itemNFT = _itemNFT;
        treasureNFT = _treasureNFT;
        feeToken = _feeToken;
    }

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
    ) external onlyOwner returns (address _account) {
        return
            IKakarottoCharacter(characterNFT).createNFT(
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

    function createTreasure(
        address _creator,
        bytes memory _createNftSignature,
        uint256 _tokenId,
        uint256 _value,
        bytes memory data
    ) external onlyOwner {
        IKakarottoTreasure(treasureNFT).mint(
            _creator,
            _createNftSignature,
            _tokenId,
            _value,
            data
        );
    }

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
    ) external onlyOwner {
        IKakarottoItem(itemNFT).mint(
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

    function chargeFee(uint256 _fee) external {
        require(
            feeToken != address(0),
            "KakarottoFactory: Fee token is zero address"
        );
        require(
            fee != address(0),
            "KakarottoFactory: Fee address is zero address"
        );
        IERC20(feeToken).approve(address(this), _fee);
        IERC20(feeToken).safeTransferFrom(msg.sender, fee, _fee);
    }

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
