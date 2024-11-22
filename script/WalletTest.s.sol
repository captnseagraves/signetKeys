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

contract WalletTestScript is Script {
    function run() external {
        vm.startBroadcast();

        console2.log("On chain ID", block.chainid);

        CoinbaseSmartWallet wallet = CoinbaseSmartWallet(
            payable(0x2cdECc2C3FEA2B68949169d0eFA84D9517d05326)
        );

        // owners[0] = abi.encode(0xC1200B5147ba1a0348b8462D00d237016945Dfff);

        console2.log("wallet", address(wallet));

        address factoryAddress = wallet.deploymentFactoryAddress();
        console2.log("factoryAddress", factoryAddress);

        bytes[] memory owners = wallet.getDeploymentOwners();
        uint256 nonce = wallet.deploymentNonce();

        console2.log("nonce", nonce);

        address owner = abi.decode(owners[0], (address));
        console2.log("owner", owner);

        ISignetSmartWalletFactory factory = ISignetSmartWalletFactory(
            0xDD21f566b37c6Aaf1Abf024b815d802931D6D3f9
        );

        address account = factory.getAddress(owners, 0);
        console2.log("account", account);

        vm.stopBroadcast();
    }
}

// forge script script/DeployWallet.s.sol:DeployWalletScript --rpc-url $OPTIMISM_SEPOLIA_RPC_URL --private-key $OPTIMISM_SEPOLIA_PRIVATE_KEY --slow --broadcast --chain-id 11155420 --etherscan-api-key $OPTIMISM_ETHERSCAN_API_KEY --verify

// 102424 contracts deployed to optimism sepolia
// https://sepolia-optimism.etherscan.io/address/0x2cdECc2C3FEA2B68949169d0eFA84D9517d05326
