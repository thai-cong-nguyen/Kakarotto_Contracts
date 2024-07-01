// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

import "../libraries/NFTLibrary.sol";

contract KakarottoItem is ERC721, ERC721URIStorage, Ownable, ERC721Burnable {
    bytes32 public constant MINT_ACTION = keccak256("KAKAROTTO_ITEM_MINT");
    uint256 public constant MAX_ATTRIBUTE = 5;

    uint256 public tokenIdCounter;
    mapping(uint256 => NFTLibrary.ItemNftInformation) public itemInformations;

    constructor(
        address _initialOwner,
        string memory _name,
        string memory _symbol,
        uint256 _mintFee
    ) ERC721(_name, _symbol) Ownable(_initialOwner) {
        mintFee = _mintFee;
        tokenIdCounter = 0;
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

    function mint(
        address _creator,
        NFTLibrary.ItemNftInformation _itemInformation
    ) external returns (uint256 _tokenId) {
        uint256 _tokenId = tokenIdCounter;
        itemInformations[_tokenId] = _itemInformation;
        _tokenIdCounter++;

        _safeMint(_creator, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
    }
}
