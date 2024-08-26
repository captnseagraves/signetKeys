// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";

import {KeyServiceEmitter} from "../src/KeyServiceEmitter.sol";

contract DeployKeyServiceEmitterScript is Script {
    function run() external {
        vm.startBroadcast();

        console2.log("Deploying on chain ID", block.chainid);

        // deploy instance of CoinbaseSmartWallet
        KeyServiceEmitter contractInstance = new KeyServiceEmitter();

        console2.log("contractInstance", address(contractInstance));

        vm.stopBroadcast();
    }
}

// forge script script/DeployKeyServiceEmitter.s.sol:DeployKeyServiceEmitterScript
// --optimize --rpc-url $OPTIMISM_SEPOLIA_RPC_URL --private-key $OPTIMISM_SEPOLIA_PRIVATE_KEY --slow --broadcast --chain-id 11155420 --verify
