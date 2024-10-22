// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {CoinbaseSmartWallet} from "./CoinbaseSmartWallet.sol";

// @dev This is a generalized interface for smart wallet factories.
//      It does require a createAccount function from factories and will update with new supported wallets in the future.

interface ISignetSmartWalletFactory {
    function createAccount(
        bytes[] calldata owners,
        uint256 nonce
    ) external payable returns (CoinbaseSmartWallet account);

    function getAddress(
        bytes[] calldata owners,
        uint256 nonce
    ) external view returns (address);
}
