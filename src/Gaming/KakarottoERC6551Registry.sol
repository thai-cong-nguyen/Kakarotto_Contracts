// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Create2.sol";

import "./interfaces/IERC6551Registry.sol";

contract KakarottoERC6551Registry is IERC6551Registry {
    address public immutable implementation;

    mapping(address => bool) public accounts;

    constructor(address _implementation) {
        implementation = _implementation;
    }

    function createAccount(
        address _implementation,
        bytes32 _salt,
        uint256 _chainId,
        address _tokenContract,
        uint256 _tokenId,
        bytes memory _initData
    ) external payable returns (address) {
        return
            _createAccount(
                _implementation,
                _salt,
                _chainId,
                _tokenContract,
                _tokenId,
                _initData
            );
    }

    function _createAccount(
        address _implementation,
        bytes32 _salt,
        uint256 _chainId,
        address _tokenContract,
        uint256 _tokenId,
        bytes memory _initData
    ) internal returns (address) {
        bytes memory code = _creationCode(
            _implementation,
            _salt,
            _chainId,
            _tokenContract,
            _tokenId
        );
        address computeAccount = Create2.computeAddress(_salt, keccak256(code));

        if (computeAccount.code.length != 0) return computeAccount;

        computeAccount = Create2.deploy(0, _salt, code);

        if (computeAccount == address(0)) {
            revert AccountCreationFailed();
        }

        if (_initData.length != 0) {
            (bool success, ) = computeAccount.call(_initData);
            if (!success)  revert AccountCreationFailed();
        }

        accounts[computeAccount] = true;
        emit ERC6551AccountCreated(
            computeAccount,
            _implementation,
            _salt,
            _chainId,
            _tokenContract,
            _tokenId
        );
        return computeAccount;
    }

    function account(
        address _implementation,
        bytes32 _salt,
        uint256 _chainId,
        address _tokenContract,
        uint256 _tokenId
    ) external view returns (address) {
        return
            _account(
                _implementation,
                _salt,
                _chainId,
                _tokenContract,
                _tokenId
            );
    }

    function _account(
        address _implementation,
        bytes32 _salt,
        uint256 _chainId,
        address _tokenContract,
        uint256 _tokenId
    ) internal returns (address) {
        bytes32 bytecodeHash = keccak256(
            _creationCode(
                _implementation,
                _salt,
                _chainId,
                _tokenContract,
                _tokenId
            )
        );
        return Create2.computeAddress(_salt, bytecodeHash);
    }

    function _creationCode(
        address _implementation,
        bytes32 _salt,
        uint256 _chainId,
        address _tokenContract,
        uint256 _tokenId
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                // ERC-1167 constructor + header
                hex"3d60ad80600a3d3981f3363d3d373d3d3d363d73",
                // implementation address
                _implementation,
                // ERC-1167 footer
                hex"5af43d82803e903d91602b57fd5bf3",
                abi.encode(_salt, _chainId, _tokenContract, _tokenId)
            );
    }
}
