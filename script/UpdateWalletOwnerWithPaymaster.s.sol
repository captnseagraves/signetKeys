// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import {UserOperation} from "account-abstraction/interfaces/UserOperation.sol";

import {CoinbaseSmartWallet} from "../src/CoinbaseSmartWallet.sol";
import {MultiOwnable} from "../src/MultiOwnable.sol";

import {SignetPaymaster} from "../src/SignetPaymaster.sol";

import {Script, console2} from "forge-std/Script.sol";

contract UpdateWalletOwnerWithPaymasterScript is Script {
    IEntryPoint constant entryPoint =
        IEntryPoint(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789);
    SignetPaymaster constant paymaster =
        SignetPaymaster(0x576F2803354d05C67425610F4D9B1068ce723c76);
    address constant accountAddress =
        0x2cdECc2C3FEA2B68949169d0eFA84D9517d05326; // Replace with your wallet address
    address constant newOwner = 0xF3aE396c509D1c4696FC77a27Ff3F5Fa9Affa83E; // Replace with the new owner's address
    address bundler =
        address(uint160(uint256(keccak256(abi.encodePacked("bundler")))));
    uint256 signerPrivateKey = vm.envUint("OPTIMISM_SEPOLIA_PRIVATE_KEY");

    uint256 userOpNonce;
    bytes userOpCalldata;

    bytes[] calls;

    function run() external {
        uint256 gas1 = gasleft();
        console2.log("gas1", gas1);

        CoinbaseSmartWallet account = CoinbaseSmartWallet(
            payable(accountAddress)
        );

        userOpNonce = entryPoint.getNonce(address(account), 8453);

        bytes4 selector = MultiOwnable.addOwnerAddress.selector;

        console2.log("userOpNonce", userOpNonce);

        console2.log("wallet", address(account));

        console2.log(
            "is newOwner an owner before the transaction?",
            account.isOwnerAddress(newOwner)
        );
        // console2.log(
        //     "account.REPLAYABLE_NONCE_KEY()",
        //     account.REPLAYABLE_NONCE_KEY()
        // );

        // console2.log(
        //     "currentNonce",
        //     entryPoint.getNonce(address(account), 8453)
        // );

        // push call to calls
        calls.push(abi.encodeWithSelector(selector, newOwner));

        // set userOpCalldata
        userOpCalldata = abi.encodeWithSelector(
            CoinbaseSmartWallet.executeWithoutChainIdValidation.selector,
            calls
        );

        bytes memory userOpPaymasterAndData = abi.encodePacked(
            address(paymaster),
            abi.encode("")
        );

        // uint256 senderBalanceBefore = address(
        //     0xC1200B5147ba1a0348b8462D00d237016945Dfff
        // ).balance;
        // console2.log("senderBalanceBefore", senderBalanceBefore);

        uint256 balanceBefore = entryPoint.balanceOf(address(paymaster));
        console2.log("balanceBefore", balanceBefore);

        UserOperation memory userOp = UserOperation({
            sender: accountAddress,
            nonce: userOpNonce,
            initCode: "",
            callData: userOpCalldata,
            callGasLimit: uint256(10_000_000),
            verificationGasLimit: uint256(10_000_000),
            preVerificationGas: uint256(1),
            maxFeePerGas: uint256(1),
            maxPriorityFeePerGas: uint256(1),
            paymasterAndData: userOpPaymasterAndData,
            signature: ""
        });

        bytes32 toSign = account.getUserOpHashWithoutChainId(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, toSign);
        userOp.signature = abi.encode(
            CoinbaseSmartWallet.SignatureWrapper(0, abi.encodePacked(r, s, v))
        );

        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = userOp;

        vm.startBroadcast();

        uint256 gas2 = gas1 - gasleft();
        console2.log("gas2", gas2);

        try entryPoint.handleOps(ops, payable(address(account))) {
            console2.log("Transaction executed successfully");
        } catch Error(string memory reason) {
            console2.log("Transaction failed with reason:", reason);
        } catch (bytes memory lowLevelData) {
            console2.log("Transaction failed with low-level error");
            console2.logBytes(lowLevelData);
        }

        uint256 gas3 = gas1 - gasleft();
        console2.log("gas3", gas3);
        console2.log("function used gas", gas3 - gas2);

        // uint256 senderBalanceAfter = address(
        //     0xC1200B5147ba1a0348b8462D00d237016945Dfff
        // ).balance;
        // console2.log("senderBalanceAfter", senderBalanceAfter);

        uint256 balanceAfter = entryPoint.balanceOf(address(paymaster));
        console2.log("balanceAfter", balanceAfter);

        require(balanceAfter == balanceBefore, "Balance did not decrease");
        // require(
        //     senderBalanceAfter == senderBalanceBefore,
        //     "Sender balance changed"
        // );

        vm.stopBroadcast();

        console2.log(
            "New owner address added:",
            account.isOwnerAddress(newOwner)
        );

        uint256 gas4 = gas1 - gasleft();
        console2.log("gas4", gas4);
    }
}

// 102424 event emitted on addOwnerAddress from OP Sepolia
// emit SignetActionRequest(sender: 0x2cdECc2C3FEA2B68949169d0eFA84D9517d05326, userOp: UserOperation({ sender: 0x2cdECc2C3FEA2B68949169d0eFA84D9517d05326, nonce: 155930327655066839810048 [1.559e23], initCode: 0x, callData: 0x2c2abd1e00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000240f0f3f24000000000000000000000000a0e957da81f77cf39596bfaa0170b7f7fb7cae0500000000000000000000000000000000000000000000000000000000, callGasLimit: 10000000 [1e7], verificationGasLimit: 10000000 [1e7], preVerificationGas: 0, maxFeePerGas: 0, maxPriorityFeePerGas: 0, paymasterAndData: 0x576f2803354d05c67425610f4d9b1068ce723c76, signature: 0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000041bad78e26fdbff22b5395acd2cc4d413a2cc2959231d7e0c03371e4e672a246e7489ab9057e43ef414078f60401a9ac8b3df7f56c41895e05c21379f3709858521c00000000000000000000000000000000000000000000000000000000000000 }))
// this event was to add 0xa0e957DA81f77Cf39596BfaA0170B7f7fb7Cae05 at owner index [1]

// emit SignetActionRequest(sender: 0x2cdECc2C3FEA2B68949169d0eFA84D9517d05326, userOp: UserOperation({ sender: 0x2cdECc2C3FEA2B68949169d0eFA84D9517d05326, nonce: 155930327655066839810049 [1.559e23], initCode: 0x, callData: 0x2c2abd1e00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000240f0f3f2400000000000000000000000005d7e9c726af8a59726cb2a08230041ff933659c00000000000000000000000000000000000000000000000000000000, callGasLimit: 10000000 [1e7], verificationGasLimit: 10000000 [1e7], preVerificationGas: 0, maxFeePerGas: 0, maxPriorityFeePerGas: 0, paymasterAndData: 0x576f2803354d05c67425610f4d9b1068ce723c76, signature: 0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000041c55d4de73f96553e8ac4eb690cf61d87ed02a7281cb593684d0a873fdbbdea3e32f8fd2125157fcc33eca856015a09a9a0e1453d26410adcd12bf51bbbec77571c00000000000000000000000000000000000000000000000000000000000000 }))
// this event was to add 0x05D7e9c726aF8a59726cb2a08230041ff933659c at owner index [2]

// this is the command that finally worked with forge script using --gas-estimate-multiplier 130 --skip-simulation
// forge script script/UpdateWalletOwnerWithPaymaster.s.sol:UpdateWalletOwnerWithPaymasterScript --rpc-url $OPTIMISM_SEPOLIA_RPC_URL --private-key $OPTIMISM_SEPOLIA_PRIVATE_KEY --slow --broadcast --chain-id 11155420 -vvvv --gas-estimate-multiplier 130 --skip-simulation

// event from successful txn on op-sepolia
// emit SignetActionRequest(sender: 0x8AEaEa2b55b0Bb1d5a5e8e6898A175F79723922d, userOp: UserOperation({ sender: 0x8AEaEa2b55b0Bb1d5a5e8e6898A175F79723922d, nonce: 155930327655066839810049 [1.559e23], initCode: 0x, callData: 0x2c2abd1e00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000240f0f3f240000000000000000000000005ad3b55625553cef54d7561cd256658537d54aad00000000000000000000000000000000000000000000000000000000, callGasLimit: 10000000 [1e7], verificationGasLimit: 10000000 [1e7], preVerificationGas: 0, maxFeePerGas: 0, maxPriorityFeePerGas: 0, paymasterAndData: 0x, signature: 0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000041d1403d9ec0273dc6d361a188e6f4c4039dac0993cbd066cf8e32c25e13ddbf441ed15909512d37e678c308f7d13f2582a0a7dd12019c73367ae0b8e576ebd2371c00000000000000000000000000000000000000000000000000000000000000 }))

// event for 0x05D7e9c726aF8a59726cb2a08230041ff933659c
// SignetActionRequest(sender: 0x8AEaEa2b55b0Bb1d5a5e8e6898A175F79723922d, userOp: UserOperation({ sender: 0x8AEaEa2b55b0Bb1d5a5e8e6898A175F79723922d, nonce: 155930327655066839810050 [1.559e23], initCode: 0x, callData: 0x2c2abd1e00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000240f0f3f2400000000000000000000000005d7e9c726af8a59726cb2a08230041ff933659c00000000000000000000000000000000000000000000000000000000, callGasLimit: 10000000 [1e7], verificationGasLimit: 10000000 [1e7], preVerificationGas: 0, maxFeePerGas: 0, maxPriorityFeePerGas: 0, paymasterAndData: 0x, signature: 0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000041113b3e771e3c980a3c2e3cdb00e6517c441bc5399df20bb84dc09f41ef66730e20327fac08c550a7906c07de2dd8c394192cb050988789d63df9af237033ec4e1c00000000000000000000000000000000000000000000000000000000000000 }))
