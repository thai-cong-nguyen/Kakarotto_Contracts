// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721Bid {
    // EVENTS
    event BidCreated(
        bytes32 _id,
        address indexed _tokenAddress,
        uint256 indexed _tokenId,
        address indexed _bidder,
        uint256 _price,
        uint256 _expiresAt
    );
    event BidAccepted(
        bytes32 _id,
        address indexed _tokenAddress,
        uint256 indexed _tokenId,
        address _bidder,
        address indexed _seller,
        uint256 _price,
        uint256 _fee
    );
    event BidCancelled(
        bytes32 _id,
        address indexed _tokenAddress,
        uint256 indexed _tokenId,
        address indexed _bidder
    );
    event ChangedFeePercentage(uint256 _feePercentage);
    // FUNCTIONS
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) external returns (bytes4);
    function placeBid(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _price,
        uint256 _duration
    ) external;
    function removeExpiredBid(uint256 _tokenId) external;
    function cancelBid(address _tokenAddress, uint256 _tokenId) external;
}
