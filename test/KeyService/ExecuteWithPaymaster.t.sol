// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../CoinbaseSmartWallet/SmartWalletTestBase.sol";

import "../../src/KeyServiceEmitter.sol";
import "../../src/KeyServicePaymaster.sol";
import {CoinbaseSmartWalletFactory} from "../../src/CoinbaseSmartWalletFactory.sol";

import {console} from "forge-std/console.sol";

contract TestExecuteWithPaymaster is SmartWalletTestBase, KeyServiceEmitter {
    KeyServicePaymaster public paymaster;
    CoinbaseSmartWalletFactory factory;
    CoinbaseSmartWallet implementationAccount;
    CoinbaseSmartWallet createdAccount;

    bytes[] calls;

    function setUp() public override {
        super.setUp();

        implementationAccount = new CoinbaseSmartWallet();
        factory = new CoinbaseSmartWalletFactory(
            address(implementationAccount)
        );
        paymaster = new KeyServicePaymaster(entryPoint, signer);
        createdAccount = factory.createAccount(owners, 0);

        userOpNonce = account.REPLAYABLE_NONCE_KEY() << 64;

        vm.startPrank(signer);
        paymaster.addFactory(address(factory));
        vm.stopPrank();
        userOpPaymasterAndData = abi.encodePacked(address(paymaster));

        vm.deal(signer, 1 ether);
    }

    //the first goal for this test is to just get the log in the paymaster to fire

    function test_succeeds_withPaymaster_whenSelectorAllowed() public {
        // fund the paymaster
        vm.startPrank(signer);
        paymaster.deposit{value: 1 ether}();
        vm.stopPrank();

        bytes4 selector = MultiOwnable.addOwnerAddress.selector;
        assertTrue(createdAccount.canSkipChainIdValidation(selector));
        address newOwner = address(6);
        assertFalse(createdAccount.isOwnerAddress(newOwner));

        calls.push(abi.encodeWithSelector(selector, newOwner));
        userOpCalldata = abi.encodeWithSelector(
            CoinbaseSmartWallet.executeWithoutChainIdValidation.selector,
            calls
        );

        vm.expectEmit(true, true, false, false);
        emit KeyServiceActionRequest(
            address(createdAccount),
            _getUserOpWithSignature()
        );

        _sendUserOperation(_getUserOpWithSignature());
        assertTrue(createdAccount.isOwnerAddress(newOwner));
    }

    // the case I want to test here is ithe calldata being provided with executeWithoutChainIdValidation
    // but not with a valid funciton selector.

    function test_paymaster_reverts_whenSelectorNotApproved() public {
        bytes4 selector = CoinbaseSmartWallet.execute.selector;
        assertFalse(createdAccount.canSkipChainIdValidation(selector));
        bytes memory restrictedSelectorCalldata = abi.encodeWithSelector(
            selector,
            ""
        );
        calls.push(restrictedSelectorCalldata);
        userOpCalldata = abi.encodeWithSelector(
            CoinbaseSmartWallet.executeWithoutChainIdValidation.selector,
            calls
        );

        UserOperation memory executionUserOp = _getUserOpWithSignature();
        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = executionUserOp;

        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA33 reverted (or OOG)"
            )
        );

        entryPoint.handleOps(ops, payable(bundler));
    }

    function _getUserOp()
        internal
        view
        override
        returns (UserOperation memory userOp)
    {
        userOp = UserOperation({
            sender: address(createdAccount),
            nonce: userOpNonce,
            initCode: "",
            callData: userOpCalldata,
            callGasLimit: uint256(2_000_000),
            verificationGasLimit: uint256(2_000_000),
            preVerificationGas: uint256(100_000),
            maxFeePerGas: uint256(0),
            maxPriorityFeePerGas: uint256(0),
            paymasterAndData: userOpPaymasterAndData,
            signature: ""
        });
    }

    function _sendUserOperation(UserOperation memory userOp) internal override {
        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = userOp;
        entryPoint.handleOps(ops, payable(bundler));
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
