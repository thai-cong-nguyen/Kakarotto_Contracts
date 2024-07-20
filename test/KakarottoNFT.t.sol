// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/forge-std/src/Test.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

import "../src/Gaming/interfaces/IERC6551Account.sol";
import "../src/Gaming/interfaces/IERC6551Registry.sol";
import "../src/Gaming/KakarottoERC6551Account.sol";
import "../src/Gaming/KakarottoERC6551Registry.sol";
import "../src/NFTs/KakarottoCharacter.sol";
import "../src/NFTs/interfaces/IKakarottoCharacter.sol";
import {TestKakarotto} from "../src/Token/Kakarotto.sol";
import {NFTLibrary} from "../src/libraries/NFTLibrary.sol";

contract KakarottoNFTTest is Test {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    bytes32 public constant MINT_ACTION = keccak256("KAKAROTTO_MINT");
    bytes32 public constant LEVELUP_ACTION = keccak256("KAKAROTTO_LEVELUP");

    uint256 public constant MAX_LEVEL = 20;
    uint256 public constant BASE_EXP = 100;

    Account user = makeAccount("user");
    address owner = makeAddr("owner");
    IERC6551Registry accountRegistry;
    IERC6551Account implementation;
    KakarottoCharacter characterNft;
    IERC20 token;
    address payable userAccount;
    uint256 tokenId;

    function setUp() public {
        token = new TestKakarotto();
        implementation = new KakarottoERC6551Account();
        accountRegistry = new KakarottoERC6551Registry(address(implementation));
        characterNft = new KakarottoCharacter(
            "KakarottoCharacter",
            "KAKA",
            owner,
            accountRegistry,
            address(0), // battle
            address(0) // treasure
        );
    }

    modifier createNFTCharacter(address _user) {
        (address payable account, uint256 _tokenId) = _createCharacterNft(
            _user
        );
        userAccount = account;
        tokenId = _tokenId;
        _;
    }

    function testTransferNFTCharacter() public createNFTCharacter(user.addr) {
        address user2 = makeAddr("user2");

        vm.startPrank(user.addr);
        characterNft.transferFrom(user.addr, user2, tokenId);
        vm.stopPrank();

        address ownerOfTokenId = characterNft.ownerOf(tokenId);
        address ownerOfBoundAccount = IERC6551Account(userAccount).owner();

        assertEq(ownerOfTokenId, user2);
        assertEq(ownerOfBoundAccount, user2);
    }

    function testCharacterInfo() public createNFTCharacter(user.addr) {
        NFTLibrary.CharacterNftInformation memory info = characterNft
            .getCharacterInfo(tokenId);
        uint256 level = characterNft.getCharacterLevel(tokenId);
        uint256 exp = characterNft.getCharacterExp(tokenId);

        assert(level == 1);
        assert(exp == 0);
        assert(info.rarity >= 10);
        assert(info.power >= 10);
        assert(info.defend >= 10);
        assert(info.agility >= 10);
        assert(info.intelligence >= 10);
        assert(info.luck >= 10);
    }

    function _createMintMessage(
        bytes32 action,
        string memory tokenURI,
        address creator
    ) internal pure returns (bytes32 message) {
        message = keccak256(abi.encodePacked(action, tokenURI, creator));
    }

    function _signMessage(
        bytes32 message,
        uint256 privateKey
    ) private pure returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 ethSignedMessage = message.toEthSignedMessageHash();
        return vm.sign(privateKey, ethSignedMessage);
    }

    function _createMintSignature(
        bytes32 action,
        string memory tokenURI,
        address creator,
        uint256 privateKey
    ) internal returns (bytes memory signature) {
        bytes32 dataHash = _createMintMessage(action, tokenURI, creator);
        (uint8 v, bytes32 r, bytes32 s) = _signMessage(dataHash, privateKey);
        signature = abi.encodePacked(r, s, v);
    }

    function _createCharacterNft(
        address _creator
    ) private returns (address payable account, uint256 _tokenId) {
        vm.txGasPrice(1);
        string memory _tokenURI = "";
        bytes memory _createNftSignature = _createMintSignature(
            MINT_ACTION,
            _tokenURI,
            _creator,
            user.key
        );
        uint256 rarity = 10;
        uint256 power = 10;
        uint256 defend = 10;
        uint256 agility = 10;
        uint256 intelligence = 10;
        uint256 luck = 10;
        vm.prank(owner);
        uint256 gasBefore = gasleft();
        account = payable(
            characterNft.createNFT(
                _tokenURI,
                _creator,
                _createNftSignature,
                rarity,
                power,
                defend,
                agility,
                intelligence,
                luck
            )
        );
        uint256 gasAfter = gasleft();
        (, , _tokenId) = IERC6551Account(account).token();
        console2.log(
            "Gas cost for creating NFT Character: ",
            (gasBefore - gasAfter) * tx.gasprice
        );
    }
}
