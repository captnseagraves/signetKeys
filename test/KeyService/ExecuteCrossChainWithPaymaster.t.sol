// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../CoinbaseSmartWallet/SmartWalletTestBase.sol";

import "../../src/KeyServiceEmitter.sol";
import "../../src/IKeyServicePaymaster.sol";
import "../../src/KeyServicePaymaster.sol";
import "../../src/ICoinbaseSmartWalletFactory.sol";
import "../../src/CoinbaseSmartWalletFactory.sol";
import "../../src/ICoinbaseSmartWallet.sol";
import "../../src/CoinbaseSmartWallet.sol";

import {console} from "forge-std/console.sol";

contract TestExecuteCrossChainWithoutPaymaster is
    SmartWalletTestBase,
    KeyServiceEmitter
{
    CoinbaseSmartWallet public implementationAccount;
    CoinbaseSmartWalletFactory public factory;
    KeyServicePaymaster public paymaster;

    // CoinbaseSmartWallet implementationAccount;
    // ICoinbaseSmartWallet implementationAccount =
    //     ICoinbaseSmartWallet(
    //         address(0xF62849F9A0B5Bf2913b396098F7c7019b51A820a)
    //     );

    // ICoinbaseSmartWalletFactory factory =
    //     ICoinbaseSmartWalletFactory(
    //         address(0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9)
    //     );

    // IKeyServicePaymaster paymaster =
    //     IKeyServicePaymaster(
    //         address(0x2e234DAe75C793f67A35089C9d99245E1C58470b)
    //     );

    CoinbaseSmartWallet public createdMainnetAccount;
    CoinbaseSmartWallet public createdOptimismAccount;
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

        // setup mainnet implementation account
        implementationAccount = new CoinbaseSmartWallet();
        // setup mainnet factory
        factory = new CoinbaseSmartWalletFactory(
            address(implementationAccount)
        );
        // setup mainnet paymaster
        paymaster = new KeyServicePaymaster(entryPoint, signer);

        // setup mainnet userOpPaymasterAndData
        userOpPaymasterAndData = abi.encodePacked(address(paymaster));

        createdAccount = createdMainnetAccount;
        userOpNonce = createdAccount.REPLAYABLE_NONCE_KEY() << 64;

        // setup mainnet implementation account
        // vm.etch(
        //     0xF62849F9A0B5Bf2913b396098F7c7019b51A820a,
        //     Static.IMPLEMENTATION_ACCOUNT_BYTES
        // );
        // // setup mainnet factory
        // vm.etch(
        //     0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9,
        //     Static.INITALIZED_FACTORY_BYTES
        // );
        // setup mainnet paymaster
        // vm.etch(
        //     0x2e234DAe75C793f67A35089C9d99245E1C58470b,
        //     Static.PAYMASTER_BYTES
        // );

        // console.log("implementationAccount bytecode");
        // console.logBytes(address(implementationAccount).code);
        // console.log("implementationAccount address");
        // console.log(address(implementationAccount));
        // console.log("factory bytecode");
        // console.logBytes(address(factory).code);
        // console.log("factory address");
        // console.log(address(factory));
        // console.log("paymaster bytecode");
        // console.logBytes(address(paymaster).code);
        // console.log("paymaster address");
        // console.log(address(paymaster));

        // create mainnet account
        createdMainnetAccount = factory.createAccount(owners, 0);

        // console.log("signer", signer);
        // console.log("paymaster owner", paymaster.owner());

        // add factory to paymaster
        vm.startPrank(signer);
        paymaster.addFactory(address(factory));
        vm.stopPrank();

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
        vm.selectFork(mainnetFork);

        vm.deal(signer, 1 ether);
        vm.startPrank(signer);
        paymaster.deposit{value: 1 ether}();
        vm.stopPrank();

        bytes4 selector = MultiOwnable.addOwnerAddress.selector;
        assertTrue(createdMainnetAccount.canSkipChainIdValidation(selector));
        address newOwner = address(6);
        assertFalse(createdMainnetAccount.isOwnerAddress(newOwner));

        calls.push(abi.encodeWithSelector(selector, newOwner));
        userOpCalldata = abi.encodeWithSelector(
            CoinbaseSmartWallet.executeWithoutChainIdValidation.selector,
            calls
        );

        // vm.expectEmit(true, true, false, false);
        // emit KeyServiceActionRequest(
        //     address(createdAccount),
        //     _getUserOpWithSignature()
        // );

        _sendUserOperation(_getUserOpWithSignature());
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
