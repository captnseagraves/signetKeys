// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";

import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import {SignetPaymaster} from "../src/SignetPaymaster.sol";

contract PaymasterDepositAndAddFactoryScript is Script {
    function run() external {
        vm.startBroadcast();

        console2.log("Running on chain ID", block.chainid);

        SignetPaymaster paymaster = SignetPaymaster(
            0x576F2803354d05C67425610F4D9B1068ce723c76
        );

        IEntryPoint entryPoint = IEntryPoint(
            0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789
        );

        paymaster.addFactory(0xDD21f566b37c6Aaf1Abf024b815d802931D6D3f9);

        uint256 balanceBefore = entryPoint.balanceOf(address(paymaster));
        console2.log("balanceBefore", balanceBefore);

        paymaster.deposit{value: 0.01 ether}();

        uint256 balanceAfter = entryPoint.balanceOf(address(paymaster));
        console2.log("balanceAfter", balanceAfter);

        require(
            balanceAfter == balanceBefore + 0.01 ether,
            "Balance did not increase"
        );

        vm.stopBroadcast();
    }
}

// forge script script/PaymasterDepositAndAddFactory.s.sol:PaymasterDepositAndAddFactoryScript --rpc-url $OPTIMISM_SEPOLIA_RPC_URL --private-key $OPTIMISM_SEPOLIA_PRIVATE_KEY --slow --broadcast --chain-id 11155420

// 102424 0.01 ETH deposited on optimism sepolia
//https://sepolia-optimism.etherscan.io/tx/0x22bdbdf00c72f2fdad0253e11638131a39793c0db8abd08b356648a08d24b291

// 0x576F2803354d05C67425610F4D9B1068ce723c76 added to factory list
// https://sepolia-optimism.etherscan.io/tx/0x3466e4cf886adbfd3f6f842a677db4e4fc486b0ef9164862e76273f09ed08293
