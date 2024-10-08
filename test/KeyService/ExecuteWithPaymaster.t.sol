// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../CoinbaseSmartWallet/SmartWalletTestBase.sol";

import "../../src/KeyServiceEmitter.sol";
import "../../src/KeyServicePaymaster.sol";

import {console} from "forge-std/console.sol";

contract TestExecuteWithPaymaster is SmartWalletTestBase, KeyServiceEmitter {
    KeyServicePaymaster public paymaster;

    bytes[] calls;

    function setUp() public override {
        super.setUp();

        paymaster = new KeyServicePaymaster(entryPoint, signer);

        userOpNonce = account.REPLAYABLE_NONCE_KEY() << 64;
        userOpCalldata = abi.encodeWithSelector(
            CoinbaseSmartWallet.executeWithoutChainIdValidation.selector
        );

        userOpPaymasterAndData = abi.encode(address(paymaster));

        vm.deal(signer, 1 ether);
    }

    //the first goal for this test is to just get the log in the paymaster to fire

    function test_succeeds_withPaymaster_whenSelectorAllowed() public {
        // fund the paymaster
        vm.startPrank(signer);
        paymaster.deposit{value: 1 ether}();
        vm.stopPrank();

        bytes4 selector = MultiOwnable.addOwnerAddress.selector;
        assertTrue(account.canSkipChainIdValidation(selector));
        address newOwner = address(6);
        assertFalse(account.isOwnerAddress(newOwner));

        calls.push(abi.encodeWithSelector(selector, newOwner));
        userOpCalldata = abi.encodeWithSelector(
            CoinbaseSmartWallet.executeWithoutChainIdValidation.selector,
            calls
        );

        vm.expectEmit(true, true, false, false);
        emit KeyServiceActionRequest(
            address(account),
            _getUserOpWithSignature()
        );

        _sendUserOperation(_getUserOpWithSignature());
        assertTrue(account.isOwnerAddress(newOwner));
    }

    function _sendUserOperation(UserOperation memory userOp) internal override {
        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = userOp;
        entryPoint.handleOps(ops, payable(bundler));

        try entryPoint.handleOps(ops, payable(bundler)) {
            console.log("Transaction executed successfully");
        } catch Error(string memory reason) {
            console.log("Transaction failed with reason:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("Transaction failed with low-level error");
            console.logBytes(lowLevelData);
        }
    }

    function _getUserOp()
        internal
        view
        override
        returns (UserOperation memory userOp)
    {
        userOp = UserOperation({
            sender: address(account),
            nonce: userOpNonce,
            initCode: "",
            callData: userOpCalldata,
            callGasLimit: uint256(1_000_000),
            verificationGasLimit: uint256(1_000_000),
            preVerificationGas: uint256(0),
            maxFeePerGas: uint256(0),
            maxPriorityFeePerGas: uint256(0),
            paymasterAndData: userOpPaymasterAndData,
            signature: ""
        });
    }

    function _getUserOpWithSignature()
        internal
        view
        override
        returns (UserOperation memory userOp)
    {
        userOp = _getUserOp();
        userOp.signature = _sign(userOp);
    }

    function _sign(
        UserOperation memory userOp
    ) internal view override returns (bytes memory signature) {
        bytes32 toSign = account.getUserOpHashWithoutChainId(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, toSign);
        signature = abi.encode(
            CoinbaseSmartWallet.SignatureWrapper(0, abi.encodePacked(r, s, v))
        );
    }
}
