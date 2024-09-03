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
        0x8636D078EFA37b7A8003B5Ec3E38C4E2A8D18d6B; // Replace with your wallet address
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

        userOpNonce = account.REPLAYABLE_NONCE_KEY() << 64;
        bytes4 selector = MultiOwnable.addOwnerAddress.selector;

        console2.log("wallet", address(account));
        console2.log("signer", signer);
        console2.log(
            "is 0xC1200B5147ba1a0348b8462D00d237016945Dfff owner?",
            account.isOwnerAddress(0xC1200B5147ba1a0348b8462D00d237016945Dfff)
        );
        console2.log("keyServiceEmitter", account.keyServiceEmitter());
        console2.log("userOpNonce", account.REPLAYABLE_NONCE_KEY());

        // push call to calls
        calls.push(abi.encodeWithSelector(selector, newOwner));

        // set userOpCalldata
        userOpCalldata = abi.encodeWithSelector(
            CoinbaseSmartWallet.executeWithoutChainIdValidation.selector,
            calls
        );

        vm.startBroadcast(signerPrivateKey);
        _sendUserOperation(_getUserOpWithSignature());
        vm.stopBroadcast();

        console2.log(
            "New owner address added:",
            account.isOwnerAddress(newOwner)
        );
    }

    function _sendUserOperation(UserOperation memory userOp) internal {
        console2.log("sendUserOp here");

        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = userOp;
        entryPoint.handleOps(ops, payable(bundler));
    }

    function _getUserOp() internal view returns (UserOperation memory userOp) {
        console2.log("getUserOp here");

        userOp = UserOperation({
            sender: accountAddress,
            nonce: userOpNonce,
            initCode: "",
            callData: userOpCalldata,
            callGasLimit: uint256(1_000_000),
            verificationGasLimit: uint256(1_000_000),
            preVerificationGas: uint256(0),
            maxFeePerGas: uint256(0),
            maxPriorityFeePerGas: uint256(0),
            paymasterAndData: "",
            signature: ""
        });
    }

    function _getUserOpWithSignature()
        internal
        view
        returns (UserOperation memory userOp)
    {
        userOp = _getUserOp();
        userOp.signature = _sign(userOp);
    }

    function _sign(
        UserOperation memory userOp
    ) internal view virtual returns (bytes memory signature) {
        console2.log("sign here");

        bytes32 toSign = entryPoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, toSign);
        signature = abi.encodePacked(uint8(0), r, s, v);
    }
}

// forge script script/DeployWallet.s.sol:DeployWalletScript
// --rpc-url $OPTIMISM_SEPOLIA_RPC_URL --private-key $OPTIMISM_SEPOLIA_PRIVATE_KEY --slow --broadcast --chain-id 11155420 --verify
