// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFactory {
    function createNFTs(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        bytes32 _nftType,
        uint256 _rarityScore,
        uint256 _rarityScoreNormal,
        uint256 _rarityScoreMedium
    ) external returns (address _nftAddress);
}
