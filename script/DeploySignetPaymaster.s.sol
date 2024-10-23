// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {SafeSingletonDeployer} from "safe-singleton-deployer-sol/src/SafeSingletonDeployer.sol";

import {SignetPaymaster} from "../src/SignetPaymaster.sol";

contract DeploySignetPaymasterScript is Script {
    address constant EXPECTED_PAYMASTER_IMPLEMENTATION =
        0x2B5AD5c4795c026514f8317c7a215E218DcCD6cF;

    function run() external {
        console2.log("Deploying on chain ID", block.chainid);
        address implementation = SafeSingletonDeployer.broadcastDeploy({
            creationCode: type(SignetPaymaster).creationCode,
            salt: 0x48394d88ceafffaddb50ff5e10c14ee6fcc25a3ee94b6760c7195f0e9effc48f
        });
        console2.log("implementation", implementation);
        assert(implementation == EXPECTED_PAYMASTER_IMPLEMENTATION);
    }
}

// forge script script/DeploySignetEmitter.s.sol:DeploySignetPaymasterScript --rpc-url $OPTIMISM_SEPOLIA_RPC_URL --private-key $OPTIMISM_SEPOLIA_PRIVATE_KEY --slow --broadcast --chain-id 11155420 --etherscan-api-key $OPTIMISM_ETHERSCAN_API_KEY --verify
