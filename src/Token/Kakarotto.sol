// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract TestKakarotto is ERC20, Ownable {
    constructor() ERC20("TestKakarotto", "TKKRT") Ownable(msg.sender) {
        _mint(msg.sender, 100000000 * 10 ** 18);
    }
}
