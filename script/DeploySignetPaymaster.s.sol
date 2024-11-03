// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {SafeSingletonDeployer} from "safe-singleton-deployer-sol/src/SafeSingletonDeployer.sol";

import {SignetPaymaster} from "../src/SignetPaymaster.sol";

contract DeploySignetPaymasterScript is Script {
    address constant EXPECTED_PAYMASTER_IMPLEMENTATION =
        0x576F2803354d05C67425610F4D9B1068ce723c76;
    address constant EXPECTED_ENTRYPOINT =
        0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;

    address constant INITIAL_OWNER = 0xC1200B5147ba1a0348b8462D00d237016945Dfff;

    function run() external {
        console2.log("Deploying on chain ID", block.chainid);
        address implementation = SafeSingletonDeployer.broadcastDeploy({
            creationCode: type(SignetPaymaster).creationCode,
            args: abi.encode(EXPECTED_ENTRYPOINT, INITIAL_OWNER),
            salt: 0x48394d88ceafffaddb50ff5e10c14ee6fcc25a3ee94b6760c7195f0e9effc48f
        });
        console2.log("implementation", implementation);
        assert(implementation == EXPECTED_PAYMASTER_IMPLEMENTATION);
    }
}

// forge script script/DeploySignetPaymaster.s.sol:DeploySignetPaymasterScript --rpc-url $OPTIMISM_SEPOLIA_RPC_URL --private-key $OPTIMISM_SEPOLIA_PRIVATE_KEY --slow --broadcast --chain-id 11155420 --etherscan-api-key $OPTIMISM_ETHERSCAN_API_KEY --verify

// 102424 contracts deployed to optimism sepolia
// https://sepolia-optimism.etherscan.io/address/0x576F2803354d05C67425610F4D9B1068ce723c76
