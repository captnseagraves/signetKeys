// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {SafeSingletonDeployer} from "safe-singleton-deployer-sol/src/SafeSingletonDeployer.sol";

import {SignetEmitter} from "../src/SignetEmitter.sol";

contract DeploySignetEmitterScript is Script {
    address constant EXPECTED_EMITTER_IMPLEMENTATION =
        0x117DA503d0C065A99C9cc640d963Bbd7081A0beb;

    function run() external {
        console2.log("Deploying on chain ID", block.chainid);
        address implementation = SafeSingletonDeployer.broadcastDeploy({
            creationCode: type(SignetEmitter).creationCode,
            salt: 0xdb2c5a6464c79bb807c5bad0e58889aede4a0ae89558056dc22df9d520242e66
        });
        console2.log("implementation", implementation);
        assert(implementation == EXPECTED_EMITTER_IMPLEMENTATION);
    }
}

// forge script script/DeploySignetEmitter.s.sol:DeploySignetEmitterScript --rpc-url $OPTIMISM_SEPOLIA_RPC_URL --private-key $OPTIMISM_SEPOLIA_PRIVATE_KEY --slow --broadcast --chain-id 11155420 --etherscan-api-key $OPTIMISM_ETHERSCAN_API_KEY --verify
