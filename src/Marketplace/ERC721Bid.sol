// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/utils/Pausable.sol";
import "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import "lib/openzeppelin-contracts/contracts/utils/Address.sol";

import "../libraries/AuctionLibrary.sol";
import "./IERC721Bid.sol";

contract ERC721Bid is IERC721Bid, Ownable, Pausable {
    using Address for address;
    using Math for uint256;

    uint256 public constant MAX_BID_DURATION = 30 days;
    uint256 public constant MIN_BID_DURATION = 5 minutes;
    bytes4 public constant ERC721_Interface = bytes4(0x80ac58cd);
    bytes4 public constant ERC721_Received = bytes4(0x150b7a02);
    bytes public constant IS_CONTRACT = bytes("IS_CONTRACT");
    uint256 public constant PRECISION = 1000000;

    // tokenAddress => tokenId => bid Index => Bid Information
    mapping(address => mapping(uint256 => mapping(uint256 => AuctionLibrary.Bid)))
        public bidsByTokenAddress;
    // tokenAddress => tokenId => bidCounts
    mapping(address => mapping(uint256 => uint256))
        public bidCounterByTokenAddress;
    // bidId => bid Index
    mapping(bytes32 => uint256) public bidIndexByBidId;
    // tokenAddress => tokenId => bidder => bidId
    mapping(address => mapping(uint256 => mapping(address => bytes32)))
        public bidIdByTokenAddressAndBidder;

    IERC20 public feeToken;
    uint256 public feePercentage;

    constructor(address _feeToken) Ownable(msg.sender) Pausable() {
        feeToken = IERC20(_feeToken);
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
            bytes32(
                _nftAddress.verifyCallResultFromTarget(true, IS_CONTRACT)
            ) == bytes32(IS_CONTRACT),
            "KakarottoMarketplace: Address is not a contract"
        );
        require(
            IERC721(_nftAddress).supportsInterface(ERC721_Interface),
            "KakarottoMarketplace: Address is not ERC721"
        );
        _;
    }

    /**
     * @dev This is a only way to accept a bid.
     * The token owner should send the token to this contract using safeTransferFrom of ERC721.
     * The bid should be removed before accepting the bid.
     * @notice The ERC721 smart contract calls this function on the recipient after a `safeTransfer`. This function may throw to revert and reject the transfer.
     * @param _operator The address which called `safeTransferFrom` function
     * @param _from The address which previously owned the token
     * @param _tokenId The NFT identifier which is being transferred
     * @param _data Additional data with no specified format
     * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) external whenNotPaused returns (bytes4) {
        bytes32 bidId = _bytesToBytes32(_data);
        uint256 bidIndex = bidIndexByBidId[bidId];

        AuctionLibrary.Bid memory bid = _getBid(msg.sender, _tokenId, bidIndex);

        require(
            bidId == bid.id && bid.expiresAt >= block.timestamp,
            "Bid is not valid"
        );

        address bidder = bid.bidder;
        uint256 price = bid.price;

        // check the bidder balance

        delete bidsByTokenAddress[msg.sender][_tokenId][bidIndex];

        delete bidIndexByBidId[bidId];

        delete bidIdByTokenAddressAndBidder[msg.sender][_tokenId][bidder];

        delete bidCounterByTokenAddress[msg.sender][_tokenId];

        // Transfer nft to bidder
        IERC721(msg.sender).safeTransferFrom(address(this), bidder, _tokenId);

        uint256 saleFeeAmount = 0;
        // Transfer fee to owner
        if (feePercentage > 0) {
            saleFeeAmount = price.mulDiv(feePercentage, PRECISION);
            require(
                feeToken.transferFrom(bidder, owner(), saleFeeAmount),
                "Transfer failed"
            );
        }
        // Transfer net amount to seller
        require(
            feeToken.transferFrom(bidder, _from, price - saleFeeAmount),
            "Transfer failed"
        );

        emit BidAccepted(
            bidId,
            msg.sender,
            _tokenId,
            bidder,
            _from,
            price,
            saleFeeAmount
        );

        return ERC721_Received;
    }

    /**
     * @dev Place a bid for a ERC721 token
     * @param _tokenAddress - address of the ERC721 token
     * @param _tokenId - uint256 of the token Id
     * @param _price - uint256 of the bid price
     * @param _duration - uint256 of the bid duration in seconds
     */
    function placeBid(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _price,
        uint256 _duration
    ) external {
        _placeBid(_tokenAddress, _tokenId, _price, _duration);
    }
    function removeExpiredBid(uint256 _tokenId) external {}
    function cancelBid(address _tokenAddress, uint256 _tokenId) external {}

    function _placeBid(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _price,
        uint256 _duration
    )
        internal
        whenNotPaused
        verifyERC721(_tokenAddress)
        verifyZeroAmount(_price)
    {
        require(
            feeToken.balanceOf(msg.sender) >= _price,
            "Insufficient balance"
        );
        require(
            feeToken.allowance(msg.sender, address(this)) >= _price,
            "Insufficient allowance"
        );
        require(_duration >= MIN_BID_DURATION, "Duration is too short");
        require(_duration <= MAX_BID_DURATION, "Duration is too long");
        IERC721 nftContract = IERC721(_tokenAddress);
        address nftOwner = nftContract.ownerOf(_tokenId);
        require(
            nftOwner != address(0) || nftOwner != msg.sender,
            "Invalid token"
        );
        uint256 expiresAt = block.timestamp + _duration;

        bytes32 bidId = keccak256(
            abi.encodePacked(
                _tokenAddress,
                _tokenId,
                msg.sender,
                _price,
                expiresAt,
                block.timestamp
            )
        );
        uint256 bidIndex;

        // Check if a bid already exists
        if (_bidderHasABid(_tokenAddress, _tokenId, msg.sender)) {
            bytes32 oldBidId;
            (bidIndex, oldBidId, , , ) = getBidByBidder(
                _tokenAddress,
                _tokenId,
                msg.sender
            );
            delete bidIndexByBidId[oldBidId];
        } else {
            bidIndex = bidCounterByTokenAddress[_tokenAddress][_tokenId];
            bidCounterByTokenAddress[_tokenAddress][_tokenId]++;
        }

        // Set bid
        bidIdByTokenAddressAndBidder[_tokenAddress][_tokenId][
            msg.sender
        ] = bidId;
        bidIndexByBidId[bidId] = bidIndex;
        // Save bid
        bidsByTokenAddress[_tokenAddress][_tokenId][bidIndex] = AuctionLibrary
            .Bid(bidId, msg.sender, _tokenAddress, _tokenId, _price, expiresAt);

        emit BidCreated(
            bidId,
            _tokenAddress,
            _tokenId,
            msg.sender,
            _price,
            expiresAt
        );
    }

    function getBidByToken(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _bidIndex
    )
        public
        view
        returns (
            bytes32 bidId,
            address bidder,
            uint256 price,
            uint256 expiresAt
        )
    {
        AuctionLibrary.Bid memory bid = _getBid(
            _tokenAddress,
            _tokenId,
            _bidIndex
        );
        return (bid.id, bid.bidder, bid.price, bid.expiresAt);
    }

    function getBidByBidder(
        address _tokenAddress,
        uint256 _tokenId,
        address _bidder
    )
        public
        view
        returns (
            uint256 bidIndex,
            bytes32 bidId,
            address bidder,
            uint256 price,
            uint256 expiresAt
        )
    {
        bidId = bidIdByTokenAddressAndBidder[_tokenAddress][_tokenId][_bidder];
        bidIndex = bidIndexByBidId[bidId];
        (bidId, bidder, price, expiresAt) = getBidByToken(
            _tokenAddress,
            _tokenId,
            bidIndex
        );
        require(_bidder != bidder, "Bidder has no bid");
    }

    function _bytesToBytes32(
        bytes memory _data
    ) internal pure returns (bytes32) {
        require(_data.length == 32, "The data length should be 32");
        bytes32 bidId;
        assembly {
            bidId := mload(add(_data, 0x20))
        }
        return bidId;
    }

    function _getBid(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _bidIndex
    ) internal view returns (AuctionLibrary.Bid memory) {
        // tokenAddress => tokenId => bid Index => Bid Information
        return bidsByTokenAddress[_tokenAddress][_tokenId][_bidIndex];
    }

    function _bidderHasABid(
        address _tokenAddress,
        uint256 _tokenId,
        address _bidder
    ) internal view returns (bool) {
        bytes32 bidId = bidIdByTokenAddressAndBidder[_tokenAddress][_tokenId][
            _bidder
        ];
        uint256 bidIndex = bidIndexByBidId[bidId];

        if (bidIndex > 0) {
            AuctionLibrary.Bid memory bid = _getBid(
                _tokenAddress,
                _tokenId,
                bidIndex
            );
            return bid.bidder == _bidder;
        }
        return false;
    }
}
