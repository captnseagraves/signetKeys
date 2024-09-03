// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import {UserOperation} from "account-abstraction/interfaces/UserOperation.sol";

import {Script, console2} from "forge-std/Script.sol";

import {CoinbaseSmartWallet} from "../src/CoinbaseSmartWallet.sol";
import {ICoinbaseSmartWallet} from "../src/ICoinbaseSmartWallet.sol";

import {CoinbaseSmartWalletFactory} from "../src/CoinbaseSmartWalletFactory.sol";
import {ICoinbaseSmartWalletFactory} from "../src/ICoinbaseSmartWalletFactory.sol";

import {MultiOwnable} from "../src/MultiOwnable.sol";

contract DeployWalletScript is Script {
    function run() external {
        vm.startBroadcast();

        console2.log("Deploying on chain ID", block.chainid);

        ICoinbaseSmartWalletFactory factory = ICoinbaseSmartWalletFactory(
            0x055c6b31791236338DcEd5c295127DD01D55ea04
        );

        bytes[] memory owners = new bytes[](1);
        owners[0] = abi.encode(0xC1200B5147ba1a0348b8462D00d237016945Dfff);
        CoinbaseSmartWallet contractInstance = factory.createAccount(owners, 0);

        console2.log("contractInstance", address(contractInstance));
        /// expected address: 0x8AEaEa2b55b0Bb1d5a5e8e6898A175F79723922d

        vm.stopBroadcast();
    }
}

// forge script script/DeployWallet.s.sol:DeployWalletScript --rpc-url $OPTIMISM_SEPOLIA_RPC_URL --private-key $OPTIMISM_SEPOLIA_PRIVATE_KEY --slow --broadcast --chain-id 11155420 --etherscan-api-key $OPTIMISM_ETHERSCAN_API_KEY --verify
