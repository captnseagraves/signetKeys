// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICoinbaseSmartWalletFactory {
    function createAccount(
        bytes[] calldata owners,
        uint256 nonce
    ) external payable returns (CoinbaseSmartWallet account);
}
