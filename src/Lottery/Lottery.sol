// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
// import "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
// import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
// import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
// import "lib/openzeppelin-contracts/contracts/utils/Address.sol";
// import "lib/openzeppelin-contracts/contracts/utils/Pausable.sol";
// import "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

// import "lib/solady/src/utils/FixedPointMathLib.sol";

// import "./LotteryStorage.sol";

// contract Lottery is ERC721, Ownable, Pausable, LotteryStorage, ReentrancyGuard {
//     using Address for address;
//     using SafeERC20 for IERC20;
//     using FixedPointMathLib for uint256;

//     constructor(
//         address _feeToken
//     )
//         ERC721("Kakarotto Lottery", "KKRLottery")
//         Ownable(msg.sender)
//         Pausable()
//         LotteryStorage(_feeToken)
//     {}

//     modifier onlyOwnerTokenId(uint256 _tokenId) {
//         require(ownerOf(_tokenId) == msg.sender, "Not the owner of the token");
//         _;
//     }

//     modifier verifyLotteryExists(uint256 _lotteryId) {
//         require(_lotteryId < lotteryCounter, "Lottery does not exist");
//         _;
//     }

//     modifier LotteryIsNotExpired(uint256 _tokenId) {
//         require(
//             block.timestamp < lotteries[_tokenId].endTime,
//             "Lottery is expired"
//         );
//         _;
//     }

//     modifier LotteryIsNotStarted(uint256 _tokenId) {
//         require(
//             block.timestamp < lotteries[_tokenId].startTime,
//             "Lottery has not been started"
//         );
//         _;
//     }

//     function createNewLottery(
//         uint256 ticketPrice,
//         uint256 startTime,
//         uint256 endTime,
//         uint256 totalRewards,
//         bool nftReward,
//         uint256 _rewardTokenId,
//         bytes32 result
//     ) external whenNotPaused nonReentrant returns (uint256 _tokenId) {
//         // Check conditionals
//         require(
//             startTime >= block.timestamp + MIN_THRESHOLD &&
//                 endTime <= startTime + MAX_DURATION &&
//                 endTime >= startTime + MIN_DURATION,
//             "Invalid time"
//         );
//         require(ticketPrice > 0, "Invalid ticket price");
//         require(nftReward && totalRewards > 0, "Invalid total rewards");

//         // Create data lottery
//         _tokenId = lotteryCounter++;
//         uint256 lotteryId = keccak256(
//             abi.encodePacked(
//                 _tokenId,
//                 ticketPrice,
//                 startTime,
//                 endTime,
//                 totalRewards,
//                 nftReward,
//                 _rewardTokenId
//             )
//         );
//         Lottery memory lottery = lotteries[_tokenId];
//         require(lottery.id == 0, "Lottery already exists");
//         lottery[_tokenId] = Lottery({
//             id: lotteryId,
//             ticketPrice: ticketPrice,
//             startTime: startTime,
//             endTime: endTime,
//             nftReward: nftReward,
//             nftTokenId: _rewardTokenId,
//             ticketsCounter: 0,
//             result: result
//         });

//         // is Lottery
//         require(LotteriesOrTickets[_tokenId] == 0, "Lottery already exists");
//         LotteriesOrTickets[_tokenId] = 2;

//         // Transfer fee & reward
//         uint256 fee = 0;
//         if (nftReward) {
//             require(
//                 IERC721(_rewardTokenId).ownerOf(_rewardTokenId) == msg.sender ||
//                     IERC721(_rewardTokenId).isApprovedForAll(
//                         msg.sender,
//                         address(this)
//                     ),
//                 "Not the owner of the reward token"
//             );
//             IERC721(rewardNFT).safeTransferFrom(
//                 msg.sender,
//                 address(this),
//                 _rewardTokenId
//             );
//         } else {
//             // Transfer reward token to contract
//             require(totalRewards > 0, "Invalid total rewards");
//             fee = FixedPointMathLib.mulWad(totalRewards, feePercent);
//         }
//         // Mint NFTs Lottery for the creator
//         _mint(msg.sender, _tokenId);
//         IERC20(feeToken).safeTransferFrom(
//             msg.sender,
//             address(this),
//             DEFAULT_FEES + fee
//         );
//         emit LotteryCreated(
//             _tokenId,
//             ticketPrice,
//             startTime,
//             endTime,
//             nftReward,
//             _rewardTokenId,
//             0
//         );
//         return _tokenId;
//     }

//     function joinLottery(uint256 _lotteryId) external whenNotPaused {
//         require(_lotteryId < lotteryCounter, "Lottery does not exist");
//     }

//     function claimReward(
//         uint256 _lotteryId,
//         uint256 _tokenId
//     )
//         external
//         whenNotPaused
//         onlyOwnerTokenId(_tokenId)
//         verifyLotteryExists(_lotteryId)
//         // lotteryIsNotStarted(_lotteryId)
//         // lotteryIsNotExpired(_lotteryId)
//     {
//         require(
//             lotteries[_lotteryId].winners.length < MAX_WINNERS,
//             "Winners already selected"
//         );
//         require(
//             lotteries[_lotteryId].winners[0] != _tokenId,
//             "Already claimed"
//         );
//         lotteries[_lotteryId].winners.push(_tokenId);
//     }

//     function checkResult(uint256 _lotteryId) external view returns (bytes32) {
//         return lotteries[_lotteryId].result;
//     }

//     function _transfer(
//         address from,
//         address to,
//         uint256 tokenId
//     ) internal override(ERC721) {
//         super._transfer(from, to, tokenId);
//     }

//     // Admin function
//     function pause() public onlyOwner whenNotPaused {
//         _pause();
//     }

//     function unpause() public onlyOwner whenPaused {
//         _unpause();
//     }

//     // to receive an ERC721 token as the reward for winning the lottery
//     function onERC721Received(
//         address _operator,
//         address _from,
//         uint256 _tokenId,
//         bytes memory _data
//     ) external whenNotPaused returns (bytes4) {
//         return this.onERC721Received.selector;
//     }

//     receive() external payable {}
// }
