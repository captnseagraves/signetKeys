// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../CoinbaseSmartWallet/SmartWalletTestBase.sol";

import "../../src/KeyServiceEmitter.sol";
import "../../src/KeyServicePaymaster.sol";
import {CoinbaseSmartWalletFactory} from "../../src/CoinbaseSmartWalletFactory.sol";
import "../../src/CoinbaseSmartWallet.sol";

import {console} from "forge-std/console.sol";

contract TestExecuteCrossChainWithoutPaymaster is
    SmartWalletTestBase,
    KeyServiceEmitter
{
    KeyServicePaymaster public optimismPaymaster;
    CoinbaseSmartWalletFactory public optimismFactory;
    CoinbaseSmartWallet public optimismImplementationAccount;
    CoinbaseSmartWallet public optimismCreatedAccount;

    CoinbaseSmartWallet public optimismImplementationReferenceAccount;

    bytes optimismImplementationReferenceAccountCode;

    bytes optimismUserOpPaymasterAndData;

    // chain forks for cross chain testing
    uint256 optimismFork;

    bytes[] calls;

    function setUp() public override {
        super.setUp();

        // setup mainnet fork
        optimismFork = vm.createSelectFork(vm.envString("OPTIMISM_RPC_URL"));

        // setup optimism implementation account
        optimismImplementationReferenceAccount = new CoinbaseSmartWallet();

        bytes32 implemetationAccountSlot0 = vm.load(
            address(optimismImplementationReferenceAccount),
            0
        );

        optimismImplementationReferenceAccountCode = address(
            optimismImplementationReferenceAccount
        ).code;

        // etch key service emitter
        vm.etch(
            0x117DA503d0C065A99C9cc640d963Bbd7081A0beb,
            Static.KEY_SERVICE_EMITTER_BYTES
        );

        vm.etch(
            0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789,
            Static.ENTRY_POINT_BYTES
        );

        vm.etch(
            0xF1F6619B38A98d6De0800F1DefC0a6399eB6d30C,
            address(optimismImplementationReferenceAccount).code
        );

        vm.store(
            0xF1F6619B38A98d6De0800F1DefC0a6399eB6d30C,
            0,
            implemetationAccountSlot0
        );

        vm.etch(
            0x6813Eb9362372EEF6200f3b1dbC3f819671cBA69,
            Static.INITALIZED_FACTORY_BYTES
        );

        optimismFactory = CoinbaseSmartWalletFactory(
            payable(address(0x6813Eb9362372EEF6200f3b1dbC3f819671cBA69))
        );

        vm.store(
            address(optimismFactory),
            0,
            bytes32(abi.encode(0xF1F6619B38A98d6De0800F1DefC0a6399eB6d30C))
        );

        vm.etch(
            0x2B5AD5c4795c026514f8317c7a215E218DcCD6cF,
            Static.PAYMASTER_BYTES
        );

        optimismPaymaster = KeyServicePaymaster(
            payable(address(0x2B5AD5c4795c026514f8317c7a215E218DcCD6cF))
        );

        vm.store(address(optimismPaymaster), 0, bytes32(abi.encode(signer)));

        vm.store(
            address(optimismPaymaster),
            bytes32(abi.encode(1)),
            bytes32(abi.encode(entryPoint))
        );

        // create optimism account
        optimismCreatedAccount = optimismFactory.createAccount(owners, 0);

        // add factory to paymaster
        vm.startPrank(signer);
        optimismPaymaster.addFactory(address(optimismFactory));
        vm.stopPrank();

        // setup optimism userOpPaymasterAndData
        optimismUserOpPaymasterAndData = abi.encodePacked(
            address(optimismPaymaster)
        );

        // this line causes an issue
        userOpNonce = optimismCreatedAccount.REPLAYABLE_NONCE_KEY() << 64;

        userOpCalldata = abi.encodeWithSelector(
            CoinbaseSmartWallet.executeWithoutChainIdValidation.selector
        );
    }

    function test_succeeds_crossChain_withPaymaster_optimism_whenSignaturesMatch()
        public
    {
        vm.selectFork(optimismFork);
        vm.deal(signer, 1 ether);
        vm.startPrank(signer);
        optimismPaymaster.deposit{value: 1 ether}();
        vm.stopPrank();
        bytes4 selector = MultiOwnable.addOwnerAddress.selector;
        assertTrue(optimismCreatedAccount.canSkipChainIdValidation(selector));
        address newOwner = address(6);
        assertFalse(optimismCreatedAccount.isOwnerAddress(newOwner));
        calls.push(abi.encodeWithSelector(selector, newOwner));
        userOpCalldata = abi.encodeWithSelector(
            CoinbaseSmartWallet.executeWithoutChainIdValidation.selector,
            calls
        );
        vm.expectEmit(true, true, false, false);
        emit KeyServiceActionRequest(
            address(optimismCreatedAccount),
            _getUserOpWithSignature()
        );
        _sendUserOperation(_getUserOpWithSignature());
        assertTrue(optimismCreatedAccount.isOwnerAddress(newOwner));
    }

    function _sendUserOperation(UserOperation memory userOp) internal override {
        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = userOp;
        entryPoint.handleOps(ops, payable(bundler));
    }

    function _getUserOp()
        internal
        view
        override
        returns (UserOperation memory userOp)
    {
        userOp = UserOperation({
            sender: address(optimismCreatedAccount),
            nonce: userOpNonce,
            initCode: "",
            callData: userOpCalldata,
            callGasLimit: uint256(20_000_000),
            verificationGasLimit: uint256(20_000_000),
            preVerificationGas: uint256(1_000_000),
            maxFeePerGas: uint256(0),
            maxPriorityFeePerGas: uint256(0),
            paymasterAndData: optimismUserOpPaymasterAndData,
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
        bytes32 toSign = optimismCreatedAccount.getUserOpHashWithoutChainId(
            userOp
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, toSign);
        signature = abi.encode(
            CoinbaseSmartWallet.SignatureWrapper(0, abi.encodePacked(r, s, v))
        );
    }
}
