// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../CoinbaseSmartWallet/SmartWalletTestBase.sol";

import "../../src/SignetEmitter.sol";

import {console} from "forge-std/console.sol";

contract TestExecuteCrossChainWithoutPaymaster is
    SmartWalletTestBase,
    SignetEmitter
{
    CoinbaseSmartWallet public mainnetAccount;
    CoinbaseSmartWallet public optimismAccount;

    // chain forks for cross chain testing
    uint256 mainnetFork;
    uint256 optimismFork;

    bytes[] calls;

    // commented out with no internet on plane flight

    function setUp() public override {
        super.setUp();
        userOpNonce = account.REPLAYABLE_NONCE_KEY() << 64;

        userOpCalldata = abi.encodeWithSelector(
            CoinbaseSmartWallet.executeWithoutChainIdValidation.selector
        );

        // setup mainnet fork
        mainnetFork = vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));
        vm.etch(address(account), bytecode);
        mainnetAccount = MockCoinbaseSmartWallet(payable(address(account)));
        vm.etch(
            0x4DE3Fbb6dF50A7e6dBEEF948dFFC1E38bECeB72C,
            Static.SIGNET_EMITTER_BYTES
        );

        // setup optimism fork
        optimismFork = vm.createSelectFork(vm.envString("OPTIMISM_RPC_URL"));
        vm.etch(address(account), bytecode);
        optimismAccount = MockCoinbaseSmartWallet(payable(address(account)));
        vm.etch(
            0x4DE3Fbb6dF50A7e6dBEEF948dFFC1E38bECeB72C,
            Static.SIGNET_EMITTER_BYTES
        );
    }

    function test_succeeds_crossChain_whenSignaturesMatch() public {
        // test operation built for local network on mainnet fork
        vm.selectFork(mainnetFork);

        bytes4 selector = MultiOwnable.addOwnerAddress.selector;
        assertTrue(mainnetAccount.canSkipChainIdValidation(selector));
        address newOwner = address(6);
        assertFalse(mainnetAccount.isOwnerAddress(newOwner));

        calls.push(abi.encodeWithSelector(selector, newOwner));
        userOpCalldata = abi.encodeWithSelector(
            CoinbaseSmartWallet.executeWithoutChainIdValidation.selector,
            calls
        );

        vm.expectEmit(true, true, false, false);
        emit SignetActionRequest(
            address(mainnetAccount),
            _getUserOpWithSignature()
        );

        _sendUserOperation(_getUserOpWithSignature());
        assertTrue(mainnetAccount.isOwnerAddress(newOwner));

        // duplicate operation on optimismFork
        vm.selectFork(optimismFork);

        vm.expectEmit(true, true, false, false);
        emit SignetActionRequest(
            address(optimismAccount),
            _getUserOpWithSignature()
        );

        _sendUserOperation(_getUserOpWithSignature());
        assertTrue(optimismAccount.isOwnerAddress(newOwner));
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
