// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IKakarottoMarketplace {
    // EVENTS
    event OrderCreated(
        bytes32 id,
        uint256 indexed assetId,
        address indexed seller,
        address indexed nftAddress,
        uint256 priceInWei,
        uint256 expiresAt
    );
    event OrderCancelled(
        bytes32 id,
        uint256 indexed assetId,
        address indexed seller,
        address indexed nftAddress
    );
    event OrderSuccessful(
        bytes32 id,
        uint256 indexed assetId,
        address indexed seller,
        address indexed buyer,
        address nftAddress,
        uint256 totalPrice
    );

    event ChangePublicationFee(uint256 publicationFeeInWei);
    event ChangeFeePercentage(uint256 feePercentage);

    // FUNCTIONS
    function setPublicationFee(uint256 _publicationFee) external;
    function setFeePercentage(uint256 _feePercentage) external;

    function createOrder(
        address _nftAddress,
        uint256 _assetId,
        uint256 priceInWei,
        uint256 expiresAt
    ) external;

    function cancelOrder(address _nftAddress, uint256 _assetId) external;

    function executeOrder(
        address _nftAddress,
        uint256 _assetId,
        uint256 _price
    ) external payable;
}
