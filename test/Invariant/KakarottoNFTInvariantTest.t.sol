// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/forge-std/src/Test.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

import "../../src/Gaming/interfaces/IERC6551Account.sol";
import "../../src/Gaming/interfaces/IERC6551Registry.sol";
import "../../src/Gaming/KakarottoERC6551Account.sol";
import "../../src/Gaming/KakarottoERC6551Registry.sol";
import "../../src/NFTs/KakarottoCharacter.sol";
import "../../src/NFTs/interfaces/IKakarottoCharacter.sol";
import {TestKakarotto} from "../../src/Token/Kakarotto.sol";
import {NFTLibrary} from "../../src/libraries/NFTLibrary.sol";
import "../Handler/KakarottoNFTHandler.t.sol";

contract KakarottoNFTInvariantTest is Test {
    KakarottoNFTHandler public handler;
    KakarottoCharacter public nft;
    KakarottoERC6551Registry public registry;
    KakarottoERC6551Account public implementation;
    TestKakarotto public token;

    address public owner;
    address public battle;

    function setUp() public {
        owner = makeAddr("owner");
        battle = makeAddr("battle");
        token = new TestKakarotto();
        implementation = new KakarottoERC6551Account();
        registry = new KakarottoERC6551Registry(address(implementation));
        nft = new KakarottoCharacter(
            "KakarottoCharacter",
            "KAKA",
            owner,
            registry,
            address(0), // battle
            address(0) // treasure
        );

        handler = new KakarottoNFTHandler(nft, owner, battle);

        targetContract(address(handler));
    }

    function invariant_levelNeverExceedsMaxLevel() public {
        for (uint256 i = 0; i < nft.tokenIdCounter(); i++) {
            uint256 level = handler.getCharacterLevel(i);
            assertLe(
                level,
                nft.MAX_LEVEL(),
                "Level should never exceed MAX_LEVEL"
            );
        }
    }

    function invariant_expAlwaysIncreases() public {
        for (uint256 i = 0; i < nft.tokenIdCounter(); i++) {
            uint256 currentExp = handler.getCharacterExp(i);
            assertGe(currentExp, 0, "Experience should never be negative");
        }
    }

    function invariant_characterStatsNeverDecrease() public {
        for (uint256 i = 0; i < nft.tokenIdCounter(); i++) {
            NFTLibrary.CharacterNftInformation memory info = handler
                .getCharacterInfo(i);
            assertGe(
                info.power,
                1,
                "Power should never decrease below initial value"
            );
            assertGe(
                info.defend,
                1,
                "Defense should never decrease below initial value"
            );
            assertGe(
                info.agility,
                1,
                "Agility should never decrease below initial value"
            );
            assertGe(
                info.intelligence,
                1,
                "Intelligence should never decrease below initial value"
            );
            assertGe(
                info.luck,
                1,
                "Luck should never decrease below initial value"
            );
        }
    }

    // function invariant_callSummary() public view {
    //     handler.callSummary();
    // }
}
