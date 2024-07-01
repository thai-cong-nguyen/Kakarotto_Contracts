// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAuctionVault {
    function withdrawETH(uint256 _amount, address _to) external payable;

    function withdrawToken(
        address _token,
        uint256 _amount,
        address _to
    ) external;

    function depositToken(address _token, uint256 _amount) external;

    function depositTokenFromAccount(
        address _token,
        uint256 _amount,
        address _account
    ) external;

    function pause() external;

    function unpause() external;

    receive() external payable;

    fallback() external payable;
}
