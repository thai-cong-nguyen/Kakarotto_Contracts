// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/utils/Pausable.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract KakarottoVault is Ownable, Pausable, ReentrancyGuard {
    event TokenDeposited(address indexed _token, uint256 _amount);
    event TokenWithdrawn(address indexed _token, uint256 _amount);
    event EthWithdrawn(uint256 _amount);
    event EthDeposited(uint256 _amount);

    constructor() Ownable(msg.sender) Pausable() {}

    function withdrawEth(
        uint256 _amount
    ) external payable onlyOwner whenNotPaused nonReentrant {
        require(_amount <= address(this).balance, "Insufficient balance");
        (bool success, bytes memory data) = payable(msg.sender).call{
            value: _amount
        }("");
        require(success, "Withdrawn: Withdraw Ether failed");
        emit EthWithdrawn(_amount);
    }

    function withdrawToken(
        address _token,
        uint256 _amount
    ) external onlyOwner whenNotPaused nonReentrant {
        IERC20 token = IERC20(_token);
        require(
            token.balanceOf(address(this)) >= _amount,
            "Withdrawn: Insufficient balance"
        );
        token.transfer(msg.sender, _amount);

        emit TokenWithdrawn(_token, _amount);
    }

    function depositToken(
        address _token,
        uint256 _amount
    ) external nonReentrant whenNotPaused {
        IERC20 token = IERC20(_token);
        require(
            token.balanceOf(msg.sender) >= _amount,
            "Deposit: Insufficient balance"
        );
        token.allowance(msg.sender, address(this));
        token.transferFrom(msg.sender, address(this), _amount);

        emit TokenDeposited(_token, _amount);
    }

    function depositTokenFromAccount(
        address _token,
        uint256 _amount,
        address _account
    ) external nonReentrant whenNotPaused {
        IERC20 token = IERC20(_token);
        require(
            token.balanceOf(_account) >= _amount,
            "Deposit: Insufficient balance"
        );
        token.allowance(_account, address(this));
        token.transferFrom(_account, address(this), _amount);

        emit TokenDeposited(_token, _amount);
    }

    receive() external payable whenNotPaused {
        emit EthDeposited(msg.value);
    }

    fallback() external payable whenNotPaused {}
}
