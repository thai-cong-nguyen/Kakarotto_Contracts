// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IKakarottoTreasure.sol";

contract KakarottoTreasure is
    ERC721,
    ERC721URIStorage,
    Ownable,
    ERC721Burnable,
    IKakarottoTreasure
{
    uint256 public tokenIdCounter;
    mapping(uint256 => uint256) public rarity;

    constructor(
        string memory _name,
        string memory _symbol,
        address _initialOwner
    ) ERC721(_name, _symbol) Ownable(_initialOwner) {}

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

    // function
    function mint(address _creator, uint256 _rarity) external onlyOwner {
        uint256 _tokenIdCounter = tokenIdCounter;
        _safeMint(_creator, _tokenIdCounter);
        _setTokenURI(_tokenIdCounter, _tokenURI);

        _tokenIdCounter++;
    }

    function burn(uint256 _tokenId) external onlyOwner {
        _burn(tokenId);
    }
}
