// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {SafeSingletonDeployer} from "safe-singleton-deployer-sol/src/SafeSingletonDeployer.sol";

import {CoinbaseSmartWallet, CoinbaseSmartWalletFactory} from "../src/CoinbaseSmartWalletFactory.sol";

contract DeployFactoryScript is Script {
    address constant EXPECTED_IMPLEMENTATION =
        0x3CA6cD6b9B9d20EC5691038d885F31E8Cf5261b5;
    // we lose the 0BASED0 address, sad.
    // could find new salt that enables another based factory address
    address constant EXPECTED_FACTORY =
        0xADA1813C74da472D7DAEFCa30F22108404c4Df16;

    function run() public {
        console2.log("Deploying on chain ID", block.chainid);
        address implementation = SafeSingletonDeployer.broadcastDeploy({
            creationCode: type(CoinbaseSmartWallet).creationCode,
            salt: 0x3438ae5ce1ff7750c1e09c4b28e2a04525da412f91561eb5b57729977f591fbb
        });
        console2.log("implementation", implementation);
        assert(implementation == EXPECTED_IMPLEMENTATION);
        address factory = SafeSingletonDeployer.broadcastDeploy({
            creationCode: type(CoinbaseSmartWalletFactory).creationCode,
            args: abi.encode(EXPECTED_IMPLEMENTATION),
            salt: 0x278d06dab87f67bb2d83470a70c8975a2c99872f290058fb43bcc47da5f0390c
        });
        console2.log("factory", factory);
        assert(factory == EXPECTED_FACTORY);
    }
}

// forge script script/DeployFactory.s.sol:DeployFactoryScript --rpc-url $OPTIMISM_SEPOLIA_RPC_URL
// --private-key $OPTIMISM_SEPOLIA_PRIVATE_KEY --slow --broadcast --chain-id 11155420 --verify
