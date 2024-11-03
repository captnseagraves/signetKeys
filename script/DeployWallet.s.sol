// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import {UserOperation} from "account-abstraction/interfaces/UserOperation.sol";

import {Script, console2} from "forge-std/Script.sol";

import {CoinbaseSmartWallet} from "../src/CoinbaseSmartWallet.sol";
import {ISignetSmartWallet} from "../src/ISignetSmartWallet.sol";

import {CoinbaseSmartWalletFactory} from "../src/CoinbaseSmartWalletFactory.sol";
import {ISignetSmartWalletFactory} from "../src/ISignetSmartWalletFactory.sol";

import {MultiOwnable} from "../src/MultiOwnable.sol";

contract DeployWalletScript is Script {
    function run() external {
        vm.startBroadcast();

        console2.log("Deploying on chain ID", block.chainid);

        ISignetSmartWalletFactory factory = ISignetSmartWalletFactory(
            0xDD21f566b37c6Aaf1Abf024b815d802931D6D3f9
        );

        bytes[] memory owners = new bytes[](1);
        owners[0] = abi.encode(0xC1200B5147ba1a0348b8462D00d237016945Dfff);
        CoinbaseSmartWallet contractInstance = factory.createAccount(owners, 0);

        console2.log("contractInstance", address(contractInstance));

        vm.stopBroadcast();
    }
}

// forge script script/DeployWallet.s.sol:DeployWalletScript --rpc-url $OPTIMISM_SEPOLIA_RPC_URL --private-key $OPTIMISM_SEPOLIA_PRIVATE_KEY --slow --broadcast --chain-id 11155420 --etherscan-api-key $OPTIMISM_ETHERSCAN_API_KEY --verify

// 102424 contracts deployed to optimism sepolia
// https://sepolia-optimism.etherscan.io/address/0x2cdECc2C3FEA2B68949169d0eFA84D9517d05326
