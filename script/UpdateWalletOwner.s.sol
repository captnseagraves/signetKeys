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

contract UpdateWalletOwnerScript is Script {
    IEntryPoint constant entryPoint =
        IEntryPoint(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789);
    address constant accountAddress =
        0x8AEaEa2b55b0Bb1d5a5e8e6898A175F79723922d; // Replace with your wallet address
    address constant newOwner = 0x5Ad3b55625553CEf54D7561cD256658537d54AAd; // Replace with the new owner's address
    address bundler =
        address(uint160(uint256(keccak256(abi.encodePacked("bundler")))));
    uint256 signerPrivateKey = vm.envUint("OPTIMISM_SEPOLIA_PRIVATE_KEY");
    address signer = vm.addr(signerPrivateKey);

    uint256 userOpNonce;
    bytes userOpCalldata;

    bytes[] calls;
    // bytes[] memory calls = new bytes[](1);

    function run() external {
        CoinbaseSmartWallet account = CoinbaseSmartWallet(
            payable(accountAddress)
        );

        uint256 accountNonce = account.REPLAYABLE_NONCE_KEY() << 64;

        userOpNonce = entryPoint.getNonce(address(account), accountNonce);

        // userOpNonce = account.REPLAYABLE_NONCE_KEY() << 64;
        // // incremented by 1 for 1 successful txn, will need to be each txn.

        // userOpNonce += 1;
        bytes4 selector = MultiOwnable.addOwnerAddress.selector;

        console2.log("wallet", address(account));
        console2.log("signer", signer);
        console2.log(
            "is 0xC1200B5147ba1a0348b8462D00d237016945Dfff owner?",
            account.isOwnerAddress(0xC1200B5147ba1a0348b8462D00d237016945Dfff)
        );
        console2.log(
            "is newOwner 0x5Ad3b55625553CEf54D7561cD256658537d54AAd owner?",
            account.isOwnerAddress(0x5Ad3b55625553CEf54D7561cD256658537d54AAd)
        );
        console2.log("keyServiceEmitter", account.keyServiceEmitter());
        console2.log(
            "account.REPLAYABLE_NONCE_KEY()",
            account.REPLAYABLE_NONCE_KEY()
        );
        console2.log("userOpNonce", userOpNonce + 1);

        console2.log(
            "currentNonce",
            entryPoint.getNonce(address(account), 8453)
        );

        // push call to calls
        calls.push(abi.encodeWithSelector(selector, newOwner));

        // set userOpCalldata
        userOpCalldata = abi.encodeWithSelector(
            CoinbaseSmartWallet.executeWithoutChainIdValidation.selector,
            calls
        );

        UserOperation memory userOp = UserOperation({
            sender: accountAddress,
            nonce: userOpNonce,
            initCode: "",
            callData: userOpCalldata,
            callGasLimit: uint256(10_000_000),
            verificationGasLimit: uint256(10_000_000),
            preVerificationGas: uint256(0),
            maxFeePerGas: uint256(0),
            maxPriorityFeePerGas: uint256(0),
            paymasterAndData: "",
            signature: ""
        });

        bytes32 toSign = account.getUserOpHashWithoutChainId(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, toSign);
        userOp.signature = abi.encode(
            CoinbaseSmartWallet.SignatureWrapper(0, abi.encodePacked(r, s, v))
        );

        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = userOp;

        vm.startBroadcast(signerPrivateKey);

        try entryPoint.handleOps(ops, payable(address(account))) {
            console2.log("Transaction executed successfully");
        } catch Error(string memory reason) {
            console2.log("Transaction failed with reason:", reason);
        } catch (bytes memory lowLevelData) {
            console2.log("Transaction failed with low-level error");
            console2.logBytes(lowLevelData);
        }

        vm.stopBroadcast();

        console2.log(
            "New owner address added:",
            account.isOwnerAddress(newOwner)
        );
    }
}

// event emitted on addOwnerAddress from OP Sepolia
// KeyServiceActionRequest(sender: 0x8AEaEa2b55b0Bb1d5a5e8e6898A175F79723922d, userOp: UserOperation({ sender: 0x8AEaEa2b55b0Bb1d5a5e8e6898A175F79723922d, nonce: 155930327655066839810048 [1.559e23], initCode: 0x, callData: 0x2c2abd1e00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000240f0f3f240000000000000000000000005ad3b55625553cef54d7561cd256658537d54aad00000000000000000000000000000000000000000000000000000000, callGasLimit: 1000000 [1e6], verificationGasLimit: 1000000 [1e6], preVerificationGas: 0, maxFeePerGas: 0, maxPriorityFeePerGas: 0, paymasterAndData: 0x, signature: 0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000004167a8172be1ee0bc65777e80e495d7494e446380505d0486530403c6e0a55b4017576aedc4fd1d70a001a0c228ddb7c9ddf81a264853d7c6e19c00d4064cda6281b00000000000000000000000000000000000000000000000000000000000000 }))

// this is the command that finally worked with forge script using --gas-estimate-multiplier 130 --skip-simulation
// forge script script/UpdateWalletOwner.s.sol:UpdateWalletOwnerScript --rpc-url $OPTIMISM_SEPOLIA_RPC_URL --private-key $OPTIMISM_SEPOLIA_PRIVATE_KEY --slow --broadcast --chain-id 11155420 -vvvv --gas-estimate-multiplier 130 --skip-simulation

// event from successful txn on op-sepolia
// emit KeyServiceActionRequest(sender: 0x8AEaEa2b55b0Bb1d5a5e8e6898A175F79723922d, userOp: UserOperation({ sender: 0x8AEaEa2b55b0Bb1d5a5e8e6898A175F79723922d, nonce: 155930327655066839810049 [1.559e23], initCode: 0x, callData: 0x2c2abd1e00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000240f0f3f240000000000000000000000005ad3b55625553cef54d7561cd256658537d54aad00000000000000000000000000000000000000000000000000000000, callGasLimit: 10000000 [1e7], verificationGasLimit: 10000000 [1e7], preVerificationGas: 0, maxFeePerGas: 0, maxPriorityFeePerGas: 0, paymasterAndData: 0x, signature: 0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000041d1403d9ec0273dc6d361a188e6f4c4039dac0993cbd066cf8e32c25e13ddbf441ed15909512d37e678c308f7d13f2582a0a7dd12019c73367ae0b8e576ebd2371c00000000000000000000000000000000000000000000000000000000000000 }))
