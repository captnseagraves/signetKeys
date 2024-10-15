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
    EntryPoint public mainnetEntryPoint;
    KeyServicePaymaster public mainnetPaymaster;
    CoinbaseSmartWalletFactory public mainnetFactory;
    CoinbaseSmartWallet public mainnetImplementationAccount;
    CoinbaseSmartWallet public mainnetCreatedAccount;

    EntryPoint public optimismEntryPoint;
    KeyServicePaymaster public optimismPaymaster;
    CoinbaseSmartWalletFactory public optimismFactory;
    CoinbaseSmartWallet public optimismImplementationAccount;
    CoinbaseSmartWallet public createdOptimismAccount;

    bytes mainnetUserOpPaymasterAndData;
    bytes optimismUserOpPaymasterAndData;

    CoinbaseSmartWallet public createdAccount;

    // chain forks for cross chain testing
    uint256 mainnetFork;
    uint256 optimismFork;

    bytes[] calls;

    function setUp() public override {
        super.setUp();

        // setup mainnet fork
        mainnetFork = vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));
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
            0x2e234DAe75C793f67A35089C9d99245E1C58470b,
            Static.IMPLEMENTATION_ACCOUNT_BYTES
        );

        mainnetImplementationAccount = CoinbaseSmartWallet(
            payable(address(0x2e234DAe75C793f67A35089C9d99245E1C58470b))
        );

        mainnetImplementationAccount.initialize(
            address(mainnetFactory),
            owners,
            0
        );

        vm.etch(
            0xF62849F9A0B5Bf2913b396098F7c7019b51A820a,
            Static.INITALIZED_FACTORY_BYTES
        );

        mainnetFactory = CoinbaseSmartWalletFactory(
            payable(address(0xF62849F9A0B5Bf2913b396098F7c7019b51A820a))
        );

        vm.store(
            address(mainnetFactory),
            0,
            bytes32(abi.encode(address(mainnetImplementationAccount)))
        );

        vm.etch(
            0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9,
            Static.PAYMASTER_BYTES
        );

        mainnetPaymaster = KeyServicePaymaster(
            payable(address(0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9))
        );

        vm.store(address(mainnetPaymaster), 0, bytes32(abi.encode(signer)));

        // setup mainnet implementation account
        // mainnetImplementationAccount = new CoinbaseSmartWallet();
        // setup mainnet factory
        // mainnetFactory = new CoinbaseSmartWalletFactory(
        //     address(mainnetImplementationAccount)
        // );
        // setup mainnet paymaster
        // mainnetPaymaster = new KeyServicePaymaster(entryPoint, signer);

        console.log(
            "mainnetImplementationAccount",
            address(mainnetImplementationAccount)
        );
        console.log("mainnetFactory", address(mainnetFactory));
        console.log("mainnetPaymaster", address(mainnetPaymaster));

        mainnetCreatedAccount = mainnetFactory.createAccount(owners, 0);

        // create mainnet account

        // add factory to paymaster
        vm.startPrank(signer);
        mainnetPaymaster.addFactory(address(mainnetFactory));
        vm.stopPrank();

        // setup mainnet userOpPaymasterAndData
        // mainnetUserOpPaymasterAndData = abi.encodePacked(
        //     address(mainnetPaymaster)
        // );

        // userOpCalldata = abi.encodeWithSelector(
        //     CoinbaseSmartWallet.executeWithoutChainIdValidation.selector
        // );

        // // setup optimism fork
        // optimismFork = vm.createSelectFork(vm.envString("OPTIMISM_RPC_URL"));
        // optimismEntryPoint = new EntryPoint();
        // optimismImplementationAccount = new CoinbaseSmartWallet();
        // optimismFactory = new CoinbaseSmartWalletFactory(
        //     address(optimismImplementationAccount)
        // );
        // optimismPaymaster = new KeyServicePaymaster(optimismEntryPoint, signer);

        // createdOptimismAccount = optimismFactory.createAccount(
        //     owners,
        //     0,
        //     address(optimismEntryPoint)
        // );

        // vm.startPrank(signer);
        // optimismPaymaster.addFactory(address(optimismFactory));
        // vm.stopPrank();

        // vm.etch(
        //     0x117DA503d0C065A99C9cc640d963Bbd7081A0beb,
        //     Static.KEY_SERVICE_EMITTER_BYTES
        // );

        // optimismUserOpPaymasterAndData = abi.encodePacked(
        //     address(optimismPaymaster)
        // );
    }

    function test_succeeds_crossChain_withPaymaster_whenSignaturesMatch()
        public
    {
        // I need to etch the factories on each chain and then create each account so they have the same address
        // test operation built for local network on mainnet fork
        // vm.selectFork(mainnetFork);
        // vm.deal(signer, 1 ether);
        // vm.startPrank(signer);
        // mainnetPaymaster.deposit{value: 1 ether}();
        // vm.stopPrank();
        // bytes4 selector = MultiOwnable.addOwnerAddress.selector;
        // assertTrue(mainnetCreatedAccount.canSkipChainIdValidation(selector));
        // address newOwner = address(6);
        // assertFalse(mainnetCreatedAccount.isOwnerAddress(newOwner));
        // calls.push(abi.encodeWithSelector(selector, newOwner));
        // userOpCalldata = abi.encodeWithSelector(
        //     CoinbaseSmartWallet.executeWithoutChainIdValidation.selector,
        //     calls
        // );
        // createdAccount = mainnetCreatedAccount;
        // userOpPaymasterAndData = mainnetUserOpPaymasterAndData;
        // userOpNonce = createdAccount.REPLAYABLE_NONCE_KEY() << 64;
        // vm.expectEmit(true, true, false, false);
        // emit KeyServiceActionRequest(
        //     address(createdAccount),
        //     _getUserOpWithSignature()
        // );
        // _sendUserOperation(_getUserOpWithSignature());
        // assertTrue(createdAccount.isOwnerAddress(newOwner));
        // // duplicate operation on optimismFork
        // vm.selectFork(optimismFork);
        // vm.deal(signer, 1 ether);
        // vm.startPrank(signer);
        // optimismPaymaster.deposit{value: 1 ether}();
        // vm.stopPrank();
        // createdAccount = createdOptimismAccount;
        // userOpPaymasterAndData = optimismUserOpPaymasterAndData;
        // vm.expectEmit(true, true, false, false);
        // emit KeyServiceActionRequest(
        //     address(createdOptimismAccount),
        //     _getUserOpWithSignature()
        // );
        // _sendUserOperation(_getUserOpWithSignature());
        // assertTrue(createdOptimismAccount.isOwnerAddress(newOwner));
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
        bytes32 toSign = createdAccount.getUserOpHashWithoutChainId(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, toSign);
        signature = abi.encode(
            CoinbaseSmartWallet.SignatureWrapper(0, abi.encodePacked(r, s, v))
        );
    }
}
