// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

import "./LotteryStorage.sol";

contract Lottery is ERC721, Ownable, Pausable, LotteryStorage {
    using Address for address;
    using SafeERC20 for IERC20;

    constructor(
        address _feeToken
    )
        ERC721("Kakarotto Lottery", "KKRLOT")
        Ownable(msg.sender)
        Pausable()
        LotteryStorage(_feeToken)
    {}

    modifier onlyOwnerTokenId(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "Not the owner of the token");
        _;
    }

    modifier verifyLotteryExists(uint256 _lotteryId) {
        require(_lotteryId < lotteryCounter, "Lottery does not exist");
        _;
    }

    modifier lotteryIsNotExpired(uint256 _lotteryId) {
        require(
            block.timestamp < lotteries[_lotteryId].endTime,
            "Lottery is expired"
        );
        _;
    }

    modifier lotteryIsNotStarted(uint256 _lotteryId) {
        require(
            block.timestamp < lotteries[_lotteryId].startTime,
            "Lottery has not been started"
        );
        _;
    }

    function createNewLottery() external whenNotPaused onlyOwner {}

    function joinLottery(uint256 _lotteryId) external whenNotPaused {
        require(_lotteryId < lotteryCounter, "Lottery does not exist");
    }

    function claimReward(
        uint256 _lotteryId,
        uint256 _tokenId
    )
        external
        whenNotPaused
        onlyOwnerTokenId(_tokenId)
        verifyLotteryExists(_lotteryId)
        lotteryIsNotStarted(_lotteryId)
        lotteryIsNotExpired(_lotteryId)
    {
        require(
            lotteries[_lotteryId].winners.length < MAX_WINNERS,
            "Winners already selected"
        );
        require(
            lotteries[_lotteryId].winners[0] != _tokenId,
            "Already claimed"
        );
        lotteries[_lotteryId].winners.push(_tokenId);
        _mint(msg.sender, _tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) {
        super._transfer(from, to, tokenId);
    }

    // function onERC721Received(
    //     address _operator,
    //     address _from,
    //     uint256 _tokenId,
    //     bytes memory _data
    // ) external whenNotPaused returns (bytes4) {
    //     return this.onERC721Received.selector;
    // }
}
