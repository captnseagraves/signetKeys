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

contract DeployWalletScript is Script {
    IEntryPoint entryPoint =
        IEntryPoint(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789);

    function run() external {
        vm.startBroadcast();

        console2.log("Deploying on chain ID", block.chainid);

        ICoinbaseSmartWalletFactory factory = ICoinbaseSmartWalletFactory(
            0xADA1813C74da472D7DAEFCa30F22108404c4Df16
        );

        CoinbaseSmartWallet contractInstance = factory.createAccount(
            [
                abi.encode(0xC1200B5147ba1a0348b8462D00d237016945Dfff),
                abi.encode(address(this))
            ],
            0
        );

        console2.log("contractInstance", address(contractInstance));

        // setKeyServiceEmitter

        contractInstance.setKeyServiceEmitter(
            0xd1b25f4f40EB3C5458747AAd994f949Be5CFc97e
        );

        // call addOwnerPublicKey

        // set userOpNonce
        uint256 userOpNonce = contractInstance.REPLAYABLE_NONCE_KEY() << 64;
        // instantiate userOpCalldata
        bytes memory userOpCalldata;
        // instantiate calls
        bytes[] memory calls = new bytes[](1);

        // set call selector
        bytes4 selector = MultiOwnable.addOwnerAddress.selector;
        // set call newOwner value
        address newOwner = address(0x5Ad3b55625553CEf54D7561cD256658537d54AAd); //captnseagraves.eth

        // push call to calls
        calls[0] = (abi.encodeWithSelector(selector, newOwner));

        // set userOpCalldata
        userOpCalldata = abi.encodeWithSelector(
            CoinbaseSmartWallet.executeWithoutChainIdValidation.selector,
            calls
        );

        // TODO: may need to deploy a paymaster at same address on each chain to make sigs work with paymasters

        // instantiate userOp
        UserOperation memory userOp = UserOperation({
            sender: address(contractInstance),
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

        uint256 signerPrivateKey = vm.envUint("OPTIMISM_SEPOLIA_PRIVATE_KEY");

        // sign userOp
        bytes32 toSign = entryPoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, toSign);

        // set userOp signature
        userOp.signature = abi.encodePacked(uint8(0), r, s, v);

        // instantiate ops
        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = userOp;

        // send userOp to entryPoint with fees going to 0 address
        entryPoint.handleOps(ops, payable(address(0)));

        console2.log(
            "new owner address updated:",
            contractInstance.isOwnerAddress(newOwner)
        );

        vm.stopBroadcast();
    }
}

// forge script script/DeployWallet.s.sol:DeployWalletScript
// --optimize --rpc-url $OPTIMISM_SEPOLIA_RPC_URL --private-key $OPTIMISM_SEPOLIA_PRIVATE_KEY --slow --broadcast --chain-id 11155420 --verify
