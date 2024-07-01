// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAuction {
    enum AuctionState {
        Pending,
        Active,
        Canceled,
        Paused,
        Completed
    }

    error AuctionCreationFailed();

    error AuctionUnexpectedState();

    error AuctionNonexistent();

    error AuctionExistent();

    error AuctionNonparticipant();

    error AuctionIsPaused();

    error AuctionIsUnpaused();

    error AuctionVaultError();

    error AuctionUnsetProperties();

    error AuctionNoncancellationBid();

    error AuctionClaimed();

    event CreatedAuction(
        uint256 _auctionId,
        address indexed _vault,
        address indexed _auctioneer,
        address indexed _nft,
        uint256 _tokenId,
        bool _feeNativeToken,
        address _feeToken,
        uint256 _initialPrice,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _createdTime
    );

    event JoinedAuction(
        uint256 _auctionId,
        uint256 _bidId,
        address indexed _bidder,
        uint256 _bidAmount,
        uint256 _snapshot
    );

    event FinishedAuction(
        uint256 _auctionId,
        uint256 _amount,
        uint256 _snapshot
    );

    event PausedAuction(uint256 _auctionId, string _reason);

    event UnpausedAuction(uint256 _auctionId);

    function createAuction(
        address _nft,
        uint256 _tokenId,
        bool _feeNativeToken,
        uint256 _initialPrice,
        uint256 _startTime,
        uint256 _endTime
    ) external returns (uint256 _auctionId);

    function joinAuction(
        uint256 _auctionId,
        uint256 _bidAmount
    ) external payable;

    function cancelBid(uint256 _auctionId, uint256 _bidId) external;

    function claimRefund(uint256 _auctionId) external;

    function finishAuction(uint256 _auctionId) external;

    function cancelAuction(uint256 _auctionId) external;

    function pauseAuction(uint256 _auctionId, string memory _reason) external;

    function unpauseAuction(uint256 _auctionId) external;

    function setFeeToken(address _feeToken) external;

    function setMinimumDelayTime(uint256 _minimumDelayTime) external;

    function setMinimumBidRate(uint256 _minimumBidRate) external;

    function setMinimumEndTime(uint256 _minimumEndTime) external;
}
