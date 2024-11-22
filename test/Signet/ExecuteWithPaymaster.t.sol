// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../CoinbaseSmartWallet/SmartWalletTestBase.sol";

import "../../src/SignetEmitter.sol";
import "../../src/SignetPaymaster.sol";
import {CoinbaseSmartWalletFactory} from "../../src/CoinbaseSmartWalletFactory.sol";

import {console} from "forge-std/console.sol";

contract TestExecuteWithPaymaster is SmartWalletTestBase, SignetEmitter {
    SignetPaymaster public paymaster;
    CoinbaseSmartWalletFactory factory;
    CoinbaseSmartWallet implementationAccount;
    CoinbaseSmartWallet createdAccount;

    EntryPoint public newEntryPoint;

    bytes[] calls;

    function setUp() public override {
        super.setUp();

        newEntryPoint = new EntryPoint();

        console2.log("newEntryPoint", address(newEntryPoint));
        console2.logBytes(address(newEntryPoint).code);

        implementationAccount = new CoinbaseSmartWallet();
        factory = new CoinbaseSmartWalletFactory(
            address(implementationAccount)
        );
        paymaster = new SignetPaymaster(entryPoint, signer);
        createdAccount = factory.createAccount(owners, 0);

        userOpNonce = account.REPLAYABLE_NONCE_KEY() << 64;

        vm.startPrank(signer);
        paymaster.addFactory(address(factory));
        vm.stopPrank();

        userOpPaymasterAndData = abi.encodePacked(address(paymaster));

        vm.deal(signer, 1 ether);
    }

    function test_paymaster_addFactory() public {
        assertTrue(paymaster.validFactories(address(factory)));
    }

    function test_paymaster_removeFactory() public {
        assertTrue(paymaster.validFactories(address(factory)));

        vm.startPrank(signer);
        paymaster.removeFactory(address(factory));
        vm.stopPrank();

        assertFalse(paymaster.validFactories(address(factory)));
    }

    function test_succeeds_withPaymaster_whenSelectorAllowed() public {
        // fund the paymaster
        vm.startPrank(signer);
        paymaster.deposit{value: 1 ether}();
        vm.stopPrank();

        console2.log(
            "deploymentFactoryAddress",
            createdAccount.deploymentFactoryAddress()
        );

        bytes[] memory owners = createdAccount.getDeploymentOwners();
        for (uint i = 0; i < owners.length; i++) {
            console2.log("Owner", i);
            console2.logBytes(owners[i]);
        }
        console2.log(
            "deploymentFactoryAddress",
            createdAccount.deploymentNonce()
        );

        bytes4 selector = MultiOwnable.addOwnerAddress.selector;
        assertTrue(createdAccount.canSkipChainIdValidation(selector));
        address newOwner = address(6);
        assertFalse(createdAccount.isOwnerAddress(newOwner));

        calls.push(abi.encodeWithSelector(selector, newOwner));
        userOpCalldata = abi.encodeWithSelector(
            CoinbaseSmartWallet.executeWithoutChainIdValidation.selector,
            calls
        );

        uint256 senderBalanceBefore = address(msg.sender).balance;
        uint256 balanceBefore = entryPoint.balanceOf(address(paymaster));

        vm.expectEmit(true, true, false, false);
        emit SignetActionRequest(
            address(createdAccount),
            _getUserOpWithSignature()
        );

        _sendUserOperation(_getUserOpWithSignature());
        assertTrue(createdAccount.isOwnerAddress(newOwner));

        uint256 senderBalanceAfter = address(msg.sender).balance;
        uint256 balanceAfter = entryPoint.balanceOf(address(paymaster));

        require(balanceAfter < balanceBefore, "Balance did not decrease");
        require(
            senderBalanceAfter == senderBalanceBefore,
            "Sender balance changed"
        );
    }

    function test_paymaster_reverts_whenSelectorNotApproved() public {
        // fund the paymaster
        vm.startPrank(signer);
        paymaster.deposit{value: 1 ether}();
        vm.stopPrank();

        bytes4 selector = CoinbaseSmartWallet.execute.selector;
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

        // EntryPoint revert message, undernearth there is SelectorNotAllowed revert
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA33 reverted (or OOG)"
            )
        );

        entryPoint.handleOps(ops, payable(bundler));
    }

    function test_revert_withPaymaster_whenFactoryNotValid() public {
        // fund the paymaster
        vm.startPrank(signer);
        paymaster.deposit{value: 1 ether}();
        vm.stopPrank();

        bytes4 selector = MultiOwnable.addOwnerAddress.selector;
        address newOwner = address(6);

        calls.push(abi.encodeWithSelector(selector, newOwner));
        userOpCalldata = abi.encodeWithSelector(
            CoinbaseSmartWallet.executeWithoutChainIdValidation.selector,
            calls
        );

        vm.startPrank(signer);
        paymaster.removeFactory(address(factory));
        vm.stopPrank();

        UserOperation memory executionUserOp = _getUserOpWithSignature();
        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = executionUserOp;

        // EntryPoint revert message, undernearth there is InvalidFactory revert
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA33 reverted (or OOG)"
            )
        );

        entryPoint.handleOps(ops, payable(bundler));
    }

    function test_revert_withPaymaster_whenSenderNotDeployedByFactory() public {
        // fund the paymaster
        vm.startPrank(signer);
        paymaster.deposit{value: 1 ether}();
        vm.stopPrank();

        bytes4 selector = MultiOwnable.addOwnerAddress.selector;
        address newOwner = address(6);

        calls.push(abi.encodeWithSelector(selector, newOwner));
        userOpCalldata = abi.encodeWithSelector(
            CoinbaseSmartWallet.executeWithoutChainIdValidation.selector,
            calls
        );

        UserOperation memory executionUserOp = _getUserOpWithSignature();
        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = executionUserOp;

        // etch factory
        vm.etch(address(vm.addr(7)), Static.INITALIZED_FACTORY_BYTES);

        vm.startPrank(signer);
        paymaster.addFactory(address(vm.addr(7)));
        vm.stopPrank();

        vm.store(
            address(ops[0].sender),
            bytes32(uint256(0)),
            bytes32(abi.encode(vm.addr(7)))
        );

        // EntryPoint revert message, undernearth there is InvalidAccount revert
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
            preVerificationGas: uint256(2_000_000),
            maxFeePerGas: uint256(1),
            maxPriorityFeePerGas: uint256(1),
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
