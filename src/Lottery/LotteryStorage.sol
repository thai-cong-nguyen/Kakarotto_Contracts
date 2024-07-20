// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LotteryStorage {
    struct Lottery {
        uint256 id;
        uint256 ticketPrice;
        uint256 startTime;
        uint256 endTime;
        bool nftReward;
        uint256 nftTokenId;
        uint256 ticketsCounter;
        bytes32 result;
    }

    struct Ticket {
        uint256 id;
        uint256 lotteryId;
        uint256 ticketNumber;
    }

    // uint256 public constant MAX_TICKETS_PER_USER = 1000;
    uint256 public constant MAX_DURATION = 1 days;
    uint256 public constant MIN_DURATION = 1 hours;
    uint256 public constant MIN_THRESHOLD = 5 minutes;
    uint256 public constant MAX_WINNERS = 1;
    uint256 public constant MAX_REWARD_TOKENS = 5;
    uint256 public constant DEFAULT_FEES = 5e15; // 0.005e

    // tokenId => uint8
    // 0: Not exist
    // 1: Ticket
    // 2: Lottery
    mapping(uint256 => uint8) public lotteriesOrTickets;
    // tokenId => Ticket
    mapping(uint256 => Ticket) public tickets;
    // tokenId => Lottery
    mapping(uint256 => Lottery) public lotteries;

    uint256 public LotteriesCounter;
    address public rewardNFT;
    address public feeToken;
    // percentage of reward pool if the lottery use feeToken as reward
    uint256 public immutable feePercent;

    constructor(address _feeToken, uint256 _feePercent, address _rewardNFT) {
        feeToken = _feeToken;
        feePercent = _feePercent;
        rewardNFT = _rewardNFT;
    }
}
