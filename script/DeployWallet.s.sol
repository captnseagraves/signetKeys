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
    IEntryPoint entryPoint =
        IEntryPoint(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789);

    function run() external {
        vm.startBroadcast();

        console2.log("Deploying on chain ID", block.chainid);

        ICoinbaseSmartWalletFactory factory = ICoinbaseSmartWalletFactory(
            0xce1520E676e5F126F024E0FCd342b66FA9f97593
        );

        bytes[] memory owners = new bytes[](2);
        owners[0] = abi.encode(address(this));
        owners[1] = abi.encode(0xC1200B5147ba1a0348b8462D00d237016945Dfff);
        CoinbaseSmartWallet contractInstance = factory.createAccount(owners, 0);

        console2.log("contractInstance", address(contractInstance));

        vm.stopBroadcast();
    }
}

// forge script script/DeployWallet.s.sol:DeployWalletScript
// --rpc-url $OPTIMISM_SEPOLIA_RPC_URL --private-key $OPTIMISM_SEPOLIA_PRIVATE_KEY --slow --broadcast --chain-id 11155420 --verify
