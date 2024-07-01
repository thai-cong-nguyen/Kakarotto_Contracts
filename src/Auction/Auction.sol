// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../libraries/AuctionLibrary.sol";
import "./interfaces/IAuction.sol";
import "./interfaces/IAuctionVault.sol";
import "./AuctionVault.sol";
import "../Clock.sol";

contract Auction is IAuction, Ownable, ReentrancyGuard, Clock {
    using SafeERC20 for IERC20;
    uint256 public auctionServiceFeeRate;

    uint256 public minimumBidRate;

    uint256 public minimumDelayTime;

    uint256 public minimumEndTime;

    address public feeToken;

    // @dev AudctionIndex => AuctionId;
    mapping(uint256 => uint256) public auctionIndex;

    // @dev AuctionId => AuctionInformation
    mapping(uint256 => AuctionLibrary.AuctionInformation) public auctions;

    uint256 public auctionCount;

    constructor(
        uint256 _auctionServiceFeeRate,
        uint256 _minimumBidRate,
        uint256 _minimumDelayTime,
        uint256 _minimumEndTime
    ) Ownable(msg.sender) ReentrancyGuard() {
        auctionServiceFeeRate = _auctionServiceFeeRate;
        minimumBidRate = _minimumBidRate;
        minimumDelayTime = _minimumDelayTime;
        minimumEndTime = _minimumEndTime;
    }

    modifier onlyAuctioneer(uint256 _auctionId) {
        AuctionLibrary.AuctionInformation storage auction = auctions[
            _auctionId
        ];
        require(
            msg.sender == auction.auctioneer || msg.sender == owner(),
            "Permission: Only auctioneer can call this function"
        );
        _;
    }

    modifier onlyBidder(uint256 _auctionId) {
        AuctionLibrary.AuctionInformation storage auction = auctions[
            _auctionId
        ];
        AuctionLibrary.AuctionPariticipant storage bidder = auction.bidders[
            msg.sender
        ];
        require(bidder.isBid, "Permission: Only bidder can call this function");
        _;
    }

    modifier isPausedAuction(uint256 _auctionId) {
        AuctionLibrary.AuctionInformation storage auction = auctions[
            _auctionId
        ];
        if (auction.paused) {
            revert AuctionIsPaused();
        }
        _;
    }

    modifier isNotZeroAddress(address _address) {
        require(_address != address(0), "Invalid address");
        _;
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // function createAuction(
    //     address _nft,
    //     uint256 _tokenId,
    //     bool _feeNativeToken,
    //     uint256 _initialPrice,
    //     uint256 _startTime,
    //     uint256 _endTime
    // ) external nonReentrant returns (uint256 _auctionId) {
    //     if (
    //         _startTime < block.timestamp + minimumDelayTime ||
    //         _endTime < _startTime + minimumEndTime ||
    //         _initialPrice <= 0 ||
    //         !(!_feeNativeToken && feeToken != address(0))
    //     ) {
    //         revert AuctionCreationFailed();
    //     }

    //     _auctionId = _createAuction(
    //         _nft,
    //         msg.sender,
    //         _tokenId,
    //         _feeNativeToken,
    //         _initialPrice,
    //         _startTime,
    //         _endTime
    //     );
    // }

    // function _createAuction(
    //     address _nft,
    //     address _auctioneer,
    //     uint256 _tokenId,
    //     bool _feeNativeToken,
    //     uint256 _initialPrice,
    //     uint256 _startTime,
    //     uint256 _endTime
    // ) internal returns (uint256 _auctionId) {
    //     _auctionId = uint256(
    //         keccak256(
    //             abi.encodePacked(
    //                 _nft, // NFT address
    //                 _tokenId, // NFT tokenId
    //                 _feeNativeToken, // Fee token
    //                 _initialPrice, // Initial price
    //                 _startTime, // Start time
    //                 _endTime, // End time
    //                 block.timestamp // Created time
    //             )
    //         )
    //     );
    //     AuctionLibrary.AuctionInformation storage auction = auctions[
    //         _auctionId
    //     ];
    //     if (auction.startTime != 0) {
    //         revert AuctionExistent();
    //     }

    //     uint256 currentTime = uint256(clock());
    //     IAuctionVault auctionVault = new AuctionVault(address(this));

    //     auctionIndex[auctionCount] = _auctionId;

    //     auction.auctionId = _auctionId;
    //     auction.auctioneer = _auctioneer;
    //     auction.vault = address(auctionVault);
    //     auction.nft = _nft;
    //     auction.feeNativeToken = _feeNativeToken;
    //     auction._tokenId = _tokenId;
    //     auction.initialPrice = _initialPrice;
    //     auction.totalBidders = 0;
    //     auction.previousBidder = address(0);
    //     auction.lastBid = _initialPrice;
    //     auction.createdTime = currentTime;
    //     auction.startTime = _startTime;
    //     auction.endTime = _endTime;
    //     auction.canceled = false;
    //     auction.paused = false;
    //     auction.claimed = false;
    //     auctionCount++;

    //     emit CreatedAuction(
    //         _auctionId,
    //         address(auctionVault),
    //         _auctioneer,
    //         _nft,
    //         _tokenId,
    //         _feeNativeToken,
    //         feeToken,
    //         _initialPrice,
    //         _startTime,
    //         _endTime,
    //         currentTime
    //     );
    // }

    // @notice MEV - gas war
    function joinAuction(
        uint256 _auctionId,
        uint256 _bidAmount
    ) external payable nonReentrant {
        _validateStateBitmap(
            _auctionId,
            _encodeStateBitmap(AuctionState.Active)
        );

        AuctionLibrary.AuctionInformation storage auction = auctions[
            _auctionId
        ];

        if (_bidAmount < auction.lastBid * minimumBidRate) {
            revert AuctionNonparticipant();
        }

        auction.lastBid = _bidAmount;
        auction.previousBidder = msg.sender;

        AuctionLibrary.AuctionPariticipant storage bidder = auction.bidders[
            msg.sender
        ];
        if (bidder.isBid) {
            bidder.totalAmount += _bidAmount;
            bidder.totalBids++;
        } else {
            bidder.participant = msg.sender;
            bidder.totalAmount = _bidAmount;
            bidder.auctionId = _auctionId;
            bidder.totalBids = 0;
            bidder.isBid = true;
            bidder.isRefunded = false;
        }

        uint256 bidId = uint256(
            keccak256(
                abi.encodePacked(
                    auction.auctionId,
                    msg.sender,
                    _bidAmount,
                    uint256(clock())
                )
            )
        );
        bidder.bids[bidId] = AuctionLibrary.Bid({
            amount: _bidAmount,
            time: uint256(clock()),
            canceled: false
        });

        auction.totalBidders++;

        // Transfer the bid amount to the Vault contract
        if (auction.feeNativeToken) {
            _depositETH(_auctionId, _bidAmount);
        } else {
            _depositToken(_auctionId, _bidAmount);
        }

        uint256 currentTime = clock();

        emit JoinedAuction(
            _auctionId,
            bidId,
            msg.sender,
            _bidAmount,
            currentTime
        );
    }

    function cancelBid(uint256 _auctionId, uint256 _bidId) external {
        _validateStateBitmap(
            _auctionId,
            _encodeStateBitmap(AuctionState.Active)
        );
        AuctionLibrary.AuctionInformation storage auction = auctions[
            _auctionId
        ];
        AuctionLibrary.AuctionPariticipant storage bidder = auction.bidders[
            msg.sender
        ];

        if (!bidder.isBid) {
            revert AuctionNoncancellationBid();
        }

        AuctionLibrary.Bid storage bid = bidder.bids[_bidId];

        if (bid.canceled) {
            revert AuctionNoncancellationBid();
        }

        bid.canceled = true;
        auction.totalBidders--;
        auction.bidders[msg.sender].totalAmount -= bid.amount;
        auction.bidders[msg.sender].totalBids--;

        // Refund the bidder
        _refundBidder(_auctionId, auction.feeNativeToken, bid.amount);
    }

    function claimRefund(uint256 _auctionId) external nonReentrant {
        AuctionLibrary.AuctionInformation storage auction = auctions[
            _auctionId
        ];
        if (!auction.canceled) {
            _validateStateBitmap(
                _auctionId,
                _encodeStateBitmap(AuctionState.Completed)
            );
        }

        AuctionLibrary.AuctionPariticipant storage bidder = auction.bidders[
            msg.sender
        ];
        if (!bidder.isBid || bidder.totalAmount == 0) {
            revert AuctionNonparticipant();
        }

        if (bidder.isRefunded) {
            revert AuctionClaimed();
        }

        bidder.isRefunded = true;

        // Refund the bidder
        _refundBidder(_auctionId, auction.feeNativeToken, bidder.totalAmount);
    }

    function _refundBidder(
        uint256 _auctionId,
        bool _feeNativeToken,
        uint256 _amount
    ) internal nonReentrant {
        if (_feeNativeToken) {
            _withdrawETH(_auctionId, _amount, msg.sender);
        } else {
            _withdrawToken(_auctionId, _amount, msg.sender);
        }
    }

    function finishAuction(
        uint256 _auctionId
    ) external onlyAuctioneer(_auctionId) {
        _validateStateBitmap(
            _auctionId,
            _encodeStateBitmap(AuctionState.Completed)
        );
        AuctionLibrary.AuctionInformation storage auction = auctions[
            _auctionId
        ];
        if (auction.claimed) {
            revert AuctionClaimed();
        }

        auction.claimed = true;
        if (auction.previousBidder != address(0)) {
            if (auction.feeNativeToken) {
                _withdrawETH(_auctionId, auction.lastBid, auction.auctioneer);
            } else {
                _withdrawToken(_auctionId, auction.lastBid, auction.auctioneer);
            }
        }

        emit FinishedAuction(_auctionId, auction.lastBid, uint256(clock()));
    }

    function cancelAuction(
        uint256 _auctionId
    ) external onlyAuctioneer(_auctionId) {
        _validateStateBitmap(
            _auctionId,
            _encodeStateBitmap(AuctionState.Active)
        );
        AuctionLibrary.AuctionInformation storage auction = auctions[
            _auctionId
        ];

        auction.canceled = true;
    }

    function state(uint256 _auctionId) public view returns (AuctionState) {
        AuctionLibrary.AuctionInformation storage auction = auctions[
            _auctionId
        ];

        bool isCanceled = auction.canceled;
        bool isPaused = auction.paused;

        if (isCanceled) {
            return AuctionState.Canceled;
        }
        if (isPaused) {
            return AuctionState.Paused;
        }

        uint256 snapshot = auctionSnapshot(auction.auctionId);
        if (snapshot == 0) {
            revert AuctionNonexistent();
        }

        uint256 currentTime = uint256(clock());
        if (snapshot >= currentTime) {
            return AuctionState.Pending;
        }

        uint256 deadline = auctionDeadline(auction.auctionId);
        if (deadline >= currentTime) {
            return AuctionState.Active;
        } else {
            return AuctionState.Completed;
        }
    }

    function pauseAuction(
        uint256 _auctionId,
        string memory _reason
    )
        external
        onlyAuctioneer(_auctionId)
        nonReentrant
        isPausedAuction(_auctionId)
    {
        AuctionLibrary.AuctionInformation storage auction = auctions[
            _auctionId
        ];

        auction.paused = true;
        address payable vault = payable(auction.vault);

        IAuctionVault(vault).pause();

        emit PausedAuction(_auctionId, _reason);
    }

    function unpauseAuction(
        uint256 _auctionId
    ) external onlyAuctioneer(_auctionId) nonReentrant {
        AuctionLibrary.AuctionInformation storage auction = auctions[
            _auctionId
        ];

        if (!auction.paused) {
            revert AuctionIsPaused();
        }

        auction.paused = false;
        address payable vault = payable(auction.vault);

        IAuctionVault(vault).unpause();

        emit UnpausedAuction(_auctionId);
    }

    /**
     * @dev Encodes a `AuctionState` into a `bytes32` representation where each bit enabled corresponds to the underlying position in the `AuctionState` enum. For example:
     *
     * 0x0000...10000
     *   ^^^^^^^------ ...
     *          ^----- Completed
     *           ^---- Paused
     *            ^--- Canceled
     *             ^-- Active
     *              ^- Pending
     *
     * @param _state State of the auction
     */
    function _encodeStateBitmap(
        AuctionState _state
    ) internal pure returns (bytes32) {
        return bytes32(1 << uint8(_state));
    }

    function _validateStateBitmap(
        uint256 _auctionId,
        bytes32 _allowedState
    ) internal view returns (AuctionState) {
        AuctionState currentState = state(_auctionId);
        if (_encodeStateBitmap(currentState) & _allowedState == bytes32(0)) {
            revert AuctionUnexpectedState();
        }
        return currentState;
    }

    // Getter functions
    function getAuctionId(uint256 _auctionIndex) public view returns (uint256) {
        return auctionIndex[_auctionIndex];
    }

    function auctionSnapshot(uint256 _auctionId) public view returns (uint256) {
        return auctions[_auctionId].startTime;
    }

    function auctionDeadline(uint256 _auctionId) public view returns (uint256) {
        return auctions[_auctionId].endTime;
    }

    // Setter functions
    function setFeeToken(address _feeToken) external onlyOwner {
        feeToken = _feeToken;
    }

    function setMinimumBidRate(uint256 _minimumBidRate) external onlyOwner {
        minimumBidRate = _minimumBidRate;
    }

    function setMinimumDelayTime(uint256 _minimumDelayTime) external onlyOwner {
        minimumDelayTime = _minimumDelayTime;
    }

    function setMinimumEndTime(uint256 _minimumEndTime) external onlyOwner {
        minimumEndTime = _minimumEndTime;
    }

    // Ownership functions from Vault
    function _withdrawETH(
        uint256 _auctionId,
        uint256 _amount,
        address _target
    ) internal nonReentrant isPausedAuction(_auctionId) {
        AuctionLibrary.AuctionInformation storage auction = auctions[
            _auctionId
        ];

        if (!auction.feeNativeToken || feeToken != address(0)) {
            revert AuctionVaultError();
        }
        if (auction.vault == address(0)) {
            revert AuctionVaultError();
        }

        IAuctionVault(payable(auction.vault)).withdrawETH(_amount, _target);
    }

    function _withdrawToken(
        uint256 _auctionId,
        uint256 _amount,
        address _target
    ) internal nonReentrant isPausedAuction(_auctionId) {
        AuctionLibrary.AuctionInformation storage auction = auctions[
            _auctionId
        ];

        if (auction.feeNativeToken || feeToken == address(0)) {
            revert AuctionVaultError();
        }
        if (auction.vault == address(0)) {
            revert AuctionVaultError();
        }

        IAuctionVault(payable(auction.vault)).withdrawToken(
            feeToken,
            _amount,
            _target
        );
    }

    function _depositETH(
        uint256 _auctionId,
        uint256 _amount
    ) internal nonReentrant isPausedAuction(_auctionId) {
        AuctionLibrary.AuctionInformation storage auction = auctions[
            _auctionId
        ];

        if (!auction.feeNativeToken || feeToken != address(0)) {
            revert AuctionVaultError();
        }
        if (auction.vault == address(0)) {
            revert AuctionVaultError();
        }

        (bool success, bytes memory data) = payable(auction.vault).call{
            value: _amount
        }("");

        if (!success) {
            revert AuctionVaultError();
        }
    }

    function _depositToken(
        uint256 _auctionId,
        uint256 _amount
    ) internal nonReentrant isPausedAuction(_auctionId) {
        AuctionLibrary.AuctionInformation storage auction = auctions[
            _auctionId
        ];

        if (auction.feeNativeToken || feeToken == address(0)) {
            revert AuctionVaultError();
        }
        if (auction.vault == address(0)) {
            revert AuctionVaultError();
        }
        IERC20(feeToken).approve(address(this), _amount);
        IERC20(feeToken).safeTransferFrom(msg.sender, address(this), _amount);
        IAuctionVault(payable(auction.vault)).depositToken(feeToken, _amount);
    }
}
