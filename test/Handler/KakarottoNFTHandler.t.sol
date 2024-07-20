// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/forge-std/src/Base.sol";
import "lib/forge-std/src/StdCheats.sol";
import "lib/forge-std/src/StdUtils.sol";
import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

import "../../src/NFTs/KakarottoCharacter.sol";
import "../../src/NFTs/interfaces/IKakarottoCharacter.sol";

contract KakarottoNFTHandler is CommonBase, StdCheats, StdUtils {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;
    
    KakarottoCharacter public nft;
    address public owner;
    address public battle;
    uint256 public constant MAX_EXP_INCREASE = 1000;

    constructor(KakarottoCharacter _nft, address _owner, address _battle) {
        nft = _nft;
        owner = _owner;
        battle = _battle;
    }

    function createNFT(
        string memory _tokenURI,
        Account memory _creator,
        uint256 rarity,
        uint256 power,
        uint256 defend,
        uint256 agility,
        uint256 intelligence,
        uint256 luck
    ) public {
        bytes32 dataHash = keccak256(
            abi.encodePacked(nft.MINT_ACTION(), _tokenURI, _creator.addr)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            _creator.key,
            dataHash.toEthSignedMessageHash()
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(owner);
        nft.createNFT(
            _tokenURI,
            _creator.addr,
            signature,
            rarity,
            power,
            defend,
            agility,
            intelligence,
            luck
        );
    }

    function levelUp(uint256 _tokenId, Account memory _creator) public {
        bytes32 dataHash = keccak256(
            abi.encodePacked(nft.LEVELUP_ACTION(), _tokenId, _creator.addr)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            _creator.key,
            dataHash.toEthSignedMessageHash()
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(owner);
        nft.levelUp(_tokenId, _creator.addr, signature);
    }

    function increaseExp(uint256 _tokenId, uint256 _value) public {
        uint256 expIncrease = bound(_value, 1, MAX_EXP_INCREASE);
        vm.prank(battle);
        nft.increaseExp(_tokenId, expIncrease);
    }

    function getCharacterInfo(
        uint256 _tokenId
    ) public view returns (NFTLibrary.CharacterNftInformation memory) {
        return nft.getCharacterInfo(_tokenId);
    }

    function getCharacterLevel(uint256 _tokenId) public view returns (uint256) {
        return nft.getCharacterLevel(_tokenId);
    }

    function getCharacterExp(uint256 _tokenId) public view returns (uint256) {
        return nft.getCharacterExp(_tokenId);
    }
}
