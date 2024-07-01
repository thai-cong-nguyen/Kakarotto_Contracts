// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LotteryStorage {
    struct Lottery {
        uint256 id;
        uint256 ticketPrice;
        uint256 startTime;
        uint256 endTime;
    }

    struct Ticket {
        uint256 lotteryId;
        uint256 ticketNumber;
    }

    uint256 public constant MAX_TICKETS_PER_USER = 1000;
    uint256 public constant MAX_DURATION = 1 days;
    uint256 public constant MAX_TICKET_PRICE = 1 ether;
    uint256 public constant MAX_WINNERS = 1;

    // Lottery Index => Lottery
    mapping(uint256 => Lottery) public lotteries;
    // LotteryId => Lottery Index
    mapping(uint256 => uint256) public lotteryIndexById;
    // tokenId => Ticket
    mapping(uint256 => Ticket) public tickets;

    uint256 public lotteryCounter;
    address public feeToken;

    constructor(address _feeToken) {
        feeToken = _feeToken;
    }
}
