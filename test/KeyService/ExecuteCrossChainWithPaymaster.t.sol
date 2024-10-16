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
    KeyServicePaymaster public mainnetPaymaster;
    CoinbaseSmartWalletFactory public mainnetFactory;
    CoinbaseSmartWallet public mainnetImplementationAccount;
    CoinbaseSmartWallet public mainnetCreatedAccount;

    KeyServicePaymaster public optimismPaymaster;
    CoinbaseSmartWalletFactory public optimismFactory;
    CoinbaseSmartWallet public optimismImplementationAccount;
    CoinbaseSmartWallet public optimismCreatedAccount;

    bytes mainnetUserOpPaymasterAndData;

    // chain forks for cross chain testing
    uint256 mainnetFork;
    uint256 optimismFork;

    bytes[] calls;

    function setUp() public override {
        super.setUp();

        // setup mainnet fork
        mainnetFork = vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

        // setup mainnet implementation account
        mainnetImplementationAccount = new CoinbaseSmartWallet();

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
            0x6813Eb9362372EEF6200f3b1dbC3f819671cBA69,
            Static.INITALIZED_FACTORY_BYTES
        );

        mainnetFactory = CoinbaseSmartWalletFactory(
            payable(address(0x6813Eb9362372EEF6200f3b1dbC3f819671cBA69))
        );

        vm.store(
            address(mainnetFactory),
            0,
            bytes32(abi.encode(address(mainnetImplementationAccount)))
        );

        vm.etch(
            0x2B5AD5c4795c026514f8317c7a215E218DcCD6cF,
            Static.PAYMASTER_BYTES
        );

        mainnetPaymaster = KeyServicePaymaster(
            payable(address(0x2B5AD5c4795c026514f8317c7a215E218DcCD6cF))
        );

        vm.store(address(mainnetPaymaster), 0, bytes32(abi.encode(signer)));

        vm.store(
            address(mainnetPaymaster),
            bytes32(abi.encode(1)),
            bytes32(abi.encode(entryPoint))
        );

        console.log("before mainnetCreatedAccount");

        // create mainnet account
        mainnetCreatedAccount = mainnetFactory.createAccount(owners, 0);

        // add factory to paymaster
        vm.startPrank(signer);
        mainnetPaymaster.addFactory(address(mainnetFactory));
        vm.stopPrank();

        // setup mainnet userOpPaymasterAndData
        mainnetUserOpPaymasterAndData = abi.encodePacked(
            address(mainnetPaymaster)
        );

        userOpNonce = mainnetCreatedAccount.REPLAYABLE_NONCE_KEY() << 64;

        userOpCalldata = abi.encodeWithSelector(
            CoinbaseSmartWallet.executeWithoutChainIdValidation.selector
        );

        /// ************************************************** ///

        // // setup optimism fork
        optimismFork = vm.createSelectFork(vm.envString("OPTIMISM_RPC_URL"));

        // setup optimism implementation account
        optimismImplementationAccount = new CoinbaseSmartWallet();

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
            0x6813Eb9362372EEF6200f3b1dbC3f819671cBA69,
            Static.INITALIZED_FACTORY_BYTES
        );

        optimismFactory = CoinbaseSmartWalletFactory(
            payable(address(0x6813Eb9362372EEF6200f3b1dbC3f819671cBA69))
        );

        vm.store(
            address(optimismFactory),
            0,
            bytes32(abi.encode(address(optimismImplementationAccount)))
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

        console.log("before optimismCreatedAccount");
        // create optimism account
        optimismCreatedAccount = optimismFactory.createAccount(owners, 0);

        // add factory to paymaster
        vm.startPrank(signer);
        optimismPaymaster.addFactory(address(optimismFactory));
        vm.stopPrank();

        userOpCalldata = abi.encodeWithSelector(
            CoinbaseSmartWallet.executeWithoutChainIdValidation.selector
        );
        /// ************************************************** ///

        console.log("mainnetCreatedAccount", address(mainnetCreatedAccount));
        console.log("optimismCreatedAccount", address(optimismCreatedAccount));
    }

    function test_succeeds_crossChain_withPaymaster_whenSignaturesMatch()
        public
    {
        vm.selectFork(mainnetFork);
        vm.deal(signer, 1 ether);
        vm.startPrank(signer);
        mainnetPaymaster.deposit{value: 1 ether}();
        vm.stopPrank();
        bytes4 selector = MultiOwnable.addOwnerAddress.selector;
        assertTrue(mainnetCreatedAccount.canSkipChainIdValidation(selector));
        address newOwner = address(6);
        assertFalse(mainnetCreatedAccount.isOwnerAddress(newOwner));
        calls.push(abi.encodeWithSelector(selector, newOwner));
        userOpCalldata = abi.encodeWithSelector(
            CoinbaseSmartWallet.executeWithoutChainIdValidation.selector,
            calls
        );
        vm.expectEmit(true, true, false, false);
        emit KeyServiceActionRequest(
            address(mainnetCreatedAccount),
            _getUserOpWithSignature()
        );
        _sendUserOperation(_getUserOpWithSignature());
        assertTrue(mainnetCreatedAccount.isOwnerAddress(newOwner));
        /// ************************************************** ///
        // duplicate operation on optimismFork
        vm.selectFork(optimismFork);
        vm.deal(signer, 1 ether);
        vm.startPrank(signer);
        optimismPaymaster.deposit{value: 1 ether}();
        vm.stopPrank();

        assertFalse(optimismCreatedAccount.isOwnerAddress(newOwner));
        // calls.push(abi.encodeWithSelector(selector2, newOwner2));
        // userOpCalldata = abi.encodeWithSelector(
        //     CoinbaseSmartWallet.executeWithoutChainIdValidation.selector,
        //     calls
        // );
        // vm.expectEmit(true, true, false, false);
        // emit KeyServiceActionRequest(
        //     address(optimismCreatedAccount),
        //     _getUserOpWithSignature()
        // );
        // _sendUserOperation(_getUserOpWithSignature());
        // assertTrue(optimismCreatedAccount.isOwnerAddress(newOwner2));
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
            sender: address(mainnetCreatedAccount),
            nonce: userOpNonce,
            initCode: "",
            callData: userOpCalldata,
            callGasLimit: uint256(2_000_000),
            verificationGasLimit: uint256(2_000_000),
            preVerificationGas: uint256(100_000),
            maxFeePerGas: uint256(0),
            maxPriorityFeePerGas: uint256(0),
            paymasterAndData: mainnetUserOpPaymasterAndData,
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
        bytes32 toSign = mainnetCreatedAccount.getUserOpHashWithoutChainId(
            userOp
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, toSign);
        signature = abi.encode(
            CoinbaseSmartWallet.SignatureWrapper(0, abi.encodePacked(r, s, v))
        );
    }
}
