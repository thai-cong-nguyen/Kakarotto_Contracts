// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

import "./IMarketplace.sol";
import "../libraries/MarketplaceLibrary.sol";

contract KakarottoMarketplace is IKakarottoMarketplace, Ownable, Pausable {
    using Math for uint256;
    using Address for address;

    IERC20 public feeToken;
    // nftAddress => assetId => Order
    mapping(address => mapping(uint256 => MarketplaceLibrary.Order))
        public orderByAssetId;
    uint256 public feePercentage;
    uint256 public publicationFeeInWei;

    bytes public constant IS_CONTRACT = bytes("IS_CONTRACT");
    uint256 public constant PRECISION = 1000000;
    bytes4 public constant ERC721_Interface = bytes4(0x80ac58cd);
    uint256 public constant THRESHOLD_ORDER_STARTED = 10 minutes;

    constructor(
        address _feeToken,
        uint256 _feePercentage,
        uint256 _publicationFeeInWei
    ) Ownable(msg.sender) {
        require(
            _feeToken.verifyCallResultFromTarget(
                _feeToken,
                true,
                IS_CONTRACT
            ) == IS_CONTRACT,
            "KakarottoMarketplace: Invalid fee token"
        );
        feeToken = IERC20(_feeToken);
        feePercentage = _feePercentage;
        publicationFeeInWei = _publicationFeeInWei;
    }

    modifier verifyZeroAmount(uint256 _amount) {
        require(
            _amount > 0,
            "KakarottoMarketplace: Amount must be greater than 0"
        );
        _;
    }

    modifier verifyZeroAddreszs(address _address) {
        require(
            _address == address(0),
            "KakarottoMarketplace: Invalid address"
        );
        _;
    }

    modifier verifyERC721(address _nftAddress) {
        require(
            _nftAddress.verifyCallResultFromTarget(
                _nftAddress,
                true,
                IS_CONTRACT
            ) == IS_CONTRACT,
            "KakarottoMarketplace: Address is not a contract"
        );
        require(
            IERC721(_nftAddress).supportsInterface(ERC721_Interface),
            "KakarottoMarketplace: Address is not ERC721"
        );
        _;
    }

    /// @dev Sets the publication fee that's charged to users to publish their assets.
    /// @param _publicationFee - Publication fee amount in wei this contract charges t publish an asset.
    function setPublicationFee(uint256 _publicationFee) external onlyOwner {
        publicationFeeInWei = _publicationFee;
        emit ChangePublicationFee(_publicationFee);
    }

    /// @dev Sets the percentage fee that will be the percentage of the final price that will be transferred to owner of the contract.
    /// @param _feePercentage - Percentage fee, from 0 to 999,999.
    function setFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(
            _feePercentage < PRECISION,
            "KakarottoMarketplace: Fee percentage must be between 0 and 999,999"
        );
        feePercentage = _feePercentage;
        emit ChangeFeePercentage(_feePercentage);
    }
    /**
     * @dev Creates a new order
     * @param _nftAddress - Non fungible contract address
     * @param _assetId - ID of the published NFT
     * @param priceInWei - Price in Wei for the supported token
     * @param expiresAt - Duration of the order
     */
    function createOrder(
        address _nftAddress,
        uint256 _assetId,
        uint256 priceInWei,
        uint256 expiresAt
    ) external whenNotPaused {
        _createOrder(_nftAddress, _assetId, priceInWei, expiresAt);
    }

    function cancelOrder(
        address _nftAddress,
        uint256 _assetId
    ) external whenNotPaused returns (MarketplaceLibrary.Order memory) {
        return _cancelOrder(_nftAddress, _assetId);
    }

    function executeOrder(
        address _nftAddress,
        uint256 _assetId,
        uint256 _price
    ) external payable whenNotPaused returns (MarketplaceLibrary.Order memory) {
        return _executeOrder(_nftAddress, _assetId, _price);
    }

    // INTERNAL FUNCTIONS

    function _createOrder(
        address _nftAddress,
        uint256 _assetId,
        uint256 _priceInWei,
        uint256 _expiresAt
    ) internal verifyZeroAmount(_priceInWei) verifyERC721(_nftAddress) {
        address sender = _msgSender();
        IERC721 nftContract = IERC721(_nftAddress);
        address assetOwner = nftContract.ownerOf(assetId);

        require(
            assetOwner == sender,
            "KakarottoMarketplace: Only the asset owner can create orders"
        );

        require(
            nftContract.getApproved(assetId) == address(this) ||
                nftContract.isApprovedForAll(sender, address(this)),
            "KakarottoMarketplace: The contract is not approved to manage the asset"
        );
        require(
            _expiresAt > uint256(block.timestamp).add(THRESHOLD_ORDER_STARTED),
            "KakarottoMarketplace: Started time should be starting after created 10 minutes"
        );

        bytes32 orderId = keccak256(
            abi.encodePacked(
                sender,
                _nftAddress,
                _assetId,
                _priceInWei,
                _expiresAt,
                block.timestamp
            )
        );

        orderByAssetId[_assetId][_nftAddress] = MarketplaceLibrary.Order(
            orderId,
            sender,
            _nftAddress,
            _priceInWei,
            _expiresAt
        );

        // Transfer publication fee to owner
        if (publicationFeeInWei > 0) {
            require(
                feeToken.transferFrom(sender, owner(), publicationFeeInWei),
                "KakarottoMarketplace: Transfer fee failed"
            );
        }

        emit OrderCreated(
            orderId,
            _assetId,
            sender,
            _nftAddress,
            _priceInWei,
            _expiresAt
        );
    }

    function _cancelOrder(
        address _nftAddress,
        uint256 _assetId
    )
        internal
        verifyZeroAddreszs(_nftAddress)
        returns (MarketplaceLibrary.Order memory)
    {
        address sender = _msgSender();
        MarketplaceLibrary.Order memory order = orderByAssetId[_nftAddress][
            _assetId
        ];
        require(
            order.expiresAt > uint256(block.timestamp),
            "KakarottoMarketplace: The order expired"
        );
        require(
            order.seller == sender || sender == owner(),
            "KakarottoMarketplace: Only the seller can cancel the order"
        );

        delete orderByAssetId[_assetId][_nftAddress];

        emit OrderCancelled(order.id, _assetId, order.seller, _nftAddress);

        return order;
    }

    function _executeOrder(
        address _nftAddress,
        uint256 _assetId,
        uint256 _price
    )
        internal
        verifyERC721(_nftAddress)
        verifyZeroAddreszs(_price)
        returns (MarketplaceLibrary.Order memory)
    {
        address sender = _msgSender();
        MarketplaceLibrary.Order memory order = orderByAssetId[_nftAddress][
            _assetId
        ];
        require(order.id != 0, "KakarottoMarketplace: Order not found");
        require(
            order.seller != address(0) && order.seller != sender,
            "KakarottoMarketplace: Invalid seller"
        );
        require(
            order.priceInWei == _price,
            "KakarottoMarketplace: Invalid price"
        );
        require(
            block.timestamp < order.expiresAt,
            "KakarottoMarketplace: Order expired"
        );
        IERC721 nftContract = IERC721(_nftAddress);
        require(
            seller == nftContract.ownerOf(_assetId),
            "KakarottoMarketplace: Seller is no longer the owner"
        );

        uint256 saleFeeAmount = 0;
        bytes32 orderId = order.id;
        delete orderByAssetId[_nftAddress][_assetId];

        // Transfer fee to owner
        if (feePercentage > 0) {
            saleFeeAmount = _price.mul(feePercentage).div(PRECISION);
            require(
                feeToken.transferFrom(sender, owner(), saleFeeAmount),
                "KakarottoMarketplace: Transfer fee failed"
            );
        }

        // Transfer sale amount to seller
        require(
            feeToken.transferFrom(
                sender,
                order.seller,
                _price.sub(saleFeeAmount)
            ),
            "KakarottoMarketplace: Transfer failed"
        );

        // Transfer asset to buyer
        nftContract.safeTransferFrom(order.seller, sender, _assetId, "");

        emit OrderSuccessful(
            orderId,
            _assetId,
            order.seller,
            sender,
            _nftAddress,
            _price
        );

        return order;
    }
}
