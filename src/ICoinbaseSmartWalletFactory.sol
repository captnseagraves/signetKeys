// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {CoinbaseSmartWallet} from "./CoinbaseSmartWallet.sol";

interface ICoinbaseSmartWalletFactory {
    function createAccount(
        bytes[] calldata owners,
        uint256 nonce
    ) external payable returns (CoinbaseSmartWallet account);

    function getAddress(
        bytes[] calldata owners,
        uint256 nonce
    ) external view returns (address);
}
