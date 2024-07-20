// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILottery {
    event LotteryCreated(
        uint256 indexed lotteryId,
        uint256 ticketPrice,
        uint256 startTime,
        uint256 endTime,
        bool nftReward,
        uint256 nftTokenId,
        uint256 ticketsCounter
    );
}
