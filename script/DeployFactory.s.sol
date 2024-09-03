// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {SafeSingletonDeployer} from "safe-singleton-deployer-sol/src/SafeSingletonDeployer.sol";

import {CoinbaseSmartWallet, CoinbaseSmartWalletFactory} from "../src/CoinbaseSmartWalletFactory.sol";

contract DeployFactoryScript is Script {
    address constant EXPECTED_IMPLEMENTATION =
        0x355cb1524266DAa444453A69611768aA3472b78F;
    // we lose the 0BASED0 address, sad.
    // could find new salt that enables another based factory address
    address constant EXPECTED_FACTORY =
        0x055c6b31791236338DcEd5c295127DD01D55ea04;

    function run() public {
        console2.log("Deploying on chain ID", block.chainid);
        address implementation = SafeSingletonDeployer.broadcastDeploy({
            creationCode: type(CoinbaseSmartWallet).creationCode,
            salt: 0x4e9d9f85f1273adf2b094bf2999f6b9876d741a29356dbd81f38207ea6f0e38b
        });
        console2.log("implementation", implementation);
        assert(implementation == EXPECTED_IMPLEMENTATION);
        address factory = SafeSingletonDeployer.broadcastDeploy({
            creationCode: type(CoinbaseSmartWalletFactory).creationCode,
            args: abi.encode(EXPECTED_IMPLEMENTATION),
            salt: 0x7a4f8c3d1b6e90b2a8f5423d7859eac49c87f3e2b0e473df8ca48a1c9d675faa
        });
        console2.log("factory", factory);
        assert(factory == EXPECTED_FACTORY);
    }
}

// forge script script/DeployFactory.s.sol:DeployFactoryScript --rpc-url $OPTIMISM_SEPOLIA_RPC_URL --private-key $OPTIMISM_SEPOLIA_PRIVATE_KEY --slow --broadcast --chain-id 11155420 --etherscan-api-key $OPTIMISM_ETHERSCAN_API_KEY --verify
