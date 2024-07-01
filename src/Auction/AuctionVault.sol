// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IAuctionVault.sol";

contract AuctionVault is IAuctionVault, Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    event TokenDeposited(address indexed _token, uint256 _amount);
    event TokenWithdrawn(address indexed _token, uint256 _amount);
    event EthWithdrawn(uint256 _amount);
    event EthDeposited(uint256 _amount);

    constructor(address _owner) Ownable(_owner) Pausable() ReentrancyGuard() {}

    function withdrawETH(
        uint256 _amount,
        address _to
    ) external payable onlyOwner whenNotPaused nonReentrant {
        require(_amount <= address(this).balance, "Insufficient balance");
        (bool success, bytes memory data) = payable(_to).call{value: _amount}(
            ""
        );
        require(success, "Withdrawn: Withdraw Ether failed");
        emit EthWithdrawn(_amount);
    }

    function withdrawToken(
        address _token,
        uint256 _amount,
        address _to
    ) external onlyOwner whenNotPaused nonReentrant {
        IERC20 token = IERC20(_token);
        require(
            token.balanceOf(address(this)) >= _amount,
            "Withdrawn: Insufficient balance"
        );
        token.approve(_to, _amount);
        token.safeTransfer(_to, _amount);

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
        token.approve(msg.sender, _amount);
        token.safeTransferFrom(msg.sender, address(this), _amount);

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
        token.safeTransferFrom(_account, address(this), _amount);

        emit TokenDeposited(_token, _amount);
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    receive() external payable whenNotPaused {
        emit EthDeposited(msg.value);
    }

    fallback() external payable whenNotPaused {}
}
