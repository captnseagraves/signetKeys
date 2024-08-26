// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";

import {CoinbaseSmartWallet} from "../src/CoinbaseSmartWalletFactory.sol";

contract DeployWalletScript is Script {
    function run() external {
        vm.startBroadcast();

        console2.log("Deploying on chain ID", block.chainid);

        // deploy instance of CoinbaseSmartWallet
        address contractInstance = new CoinbaseSmartWallet();

        console2.log("contractInstance", contractInstance);

        vm.stopBroadcast();
    }
}
