// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../CoinbaseSmartWallet/SmartWalletTestBase.sol";

import "../../src/SignetEmitter.sol";
import "../../src/SignetPaymaster.sol";
import "../../src/CoinbaseSmartWalletFactory.sol";
import "../../src/CoinbaseSmartWallet.sol";

import {console} from "forge-std/console.sol";

/// @dev this is a sister test to ExecuteCrossChainWithPaymasterMainnet.t.sol.
/// Together they show that with contracts deployed to the same address the same txn is valid and executed on multiple chains.
/// They would be in the same file and test except there seems to be a bug in Foundry with contracts at the same address on multiple forks.

contract TestExecuteCrossChainWithPaymasterOptimism is
    SmartWalletTestBase,
    SignetEmitter
{
    SignetPaymaster public optimismPaymaster;
    CoinbaseSmartWalletFactory public optimismFactory;
    CoinbaseSmartWallet public optimismCreatedAccount;
    CoinbaseSmartWallet public optimismImplementationReferenceAccount;

    uint256 optimismFork;

    bytes[] calls;

    bytes optimismUserOpPaymasterAndData;

    function setUp() public override {
        super.setUp();

        // setup mainnet fork
        optimismFork = vm.createSelectFork(vm.envString("OPTIMISM_RPC_URL"));

        /// @dev this is an unused variable, but for some reason the test fails without it. Feels like a bug in Foundry.
        // setup optimism implementation reference account
        optimismImplementationReferenceAccount = new CoinbaseSmartWallet();

        // etch key service emitter
        vm.etch(
            0x117DA503d0C065A99C9cc640d963Bbd7081A0beb,
            Static.SIGNET_EMITTER_BYTES
        );

        // etch entry point
        vm.etch(
            0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789,
            Static.ENTRY_POINT_BYTES
        );

        // etch implementation account
        vm.etch(
            0xF1F6619B38A98d6De0800F1DefC0a6399eB6d30C,
            Static.IMPLEMENTATION_ACCOUNT_BYTES
        );

        // etch factory
        vm.etch(
            0x6813Eb9362372EEF6200f3b1dbC3f819671cBA69,
            Static.INITALIZED_FACTORY_BYTES
        );

        // instantiate factory
        optimismFactory = CoinbaseSmartWalletFactory(
            payable(address(0x6813Eb9362372EEF6200f3b1dbC3f819671cBA69))
        );

        // set implementation address in factory
        vm.store(
            address(optimismFactory),
            0,
            bytes32(abi.encode(0xF1F6619B38A98d6De0800F1DefC0a6399eB6d30C))
        );

        // etch paymaster
        vm.etch(
            0x2B5AD5c4795c026514f8317c7a215E218DcCD6cF,
            Static.PAYMASTER_BYTES
        );

        // instantiate paymaster
        optimismPaymaster = SignetPaymaster(
            payable(address(0x2B5AD5c4795c026514f8317c7a215E218DcCD6cF))
        );

        // set paymaster owner
        vm.store(address(optimismPaymaster), 0, bytes32(abi.encode(signer)));

        // set entry point
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

        userOpNonce = optimismCreatedAccount.REPLAYABLE_NONCE_KEY() << 64;

        userOpCalldata = abi.encodeWithSelector(
            CoinbaseSmartWallet.executeWithoutChainIdValidation.selector
        );
    }

    function test_succeeds_crossChain_withPaymaster_optimism_whenSignaturesMatch()
        public
    {
        vm.selectFork(optimismFork);

        // paymaster funds not used in local testnet fork, but leaving here for legibility on a live testnet
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
        emit SignetActionRequest(
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
            callGasLimit: uint256(2_000_000),
            verificationGasLimit: uint256(2_000_000),
            preVerificationGas: uint256(100_000),
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
