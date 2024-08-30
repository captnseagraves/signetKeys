// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../CoinbaseSmartWallet/SmartWalletTestBase.sol";

import "../../src/KeyServiceEmitter.sol";

import {console} from "forge-std/console.sol";

contract TestExecuteCrossChainWithoutChainIdValidation is
    SmartWalletTestBase,
    KeyServiceEmitter
{
    CoinbaseSmartWallet public mainnetAccount;
    CoinbaseSmartWallet public optimismAccount;

    // chain forks for cross chain testing
    uint256 mainnetFork;
    uint256 optimismFork;

    bytes[] calls;

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
            0xd1b25f4f40EB3C5458747AAd994f949Be5CFc97e,
            Static.KEY_SERVICE_EMITTER_BYTES
        );

        // setup optimism fork
        optimismFork = vm.createSelectFork(vm.envString("OPTIMISM_RPC_URL"));
        vm.etch(address(account), bytecode);
        optimismAccount = MockCoinbaseSmartWallet(payable(address(account)));
        vm.etch(
            0xd1b25f4f40EB3C5458747AAd994f949Be5CFc97e,
            Static.KEY_SERVICE_EMITTER_BYTES
        );
    }

    function test_reverts_whenCallerNotEntryPoint() public {
        vm.expectRevert(MultiOwnable.Unauthorized.selector);
        account.executeWithoutChainIdValidation(calls);
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
        emit KeyServiceActionRequest(
            address(mainnetAccount),
            _getUserOpWithSignature()
        );

        _sendUserOperation(_getUserOpWithSignature());
        assertTrue(mainnetAccount.isOwnerAddress(newOwner));

        // duplicate operation on optimismFork
        vm.selectFork(optimismFork);

        vm.expectEmit(true, true, false, false);
        emit KeyServiceActionRequest(
            address(optimismAccount),
            _getUserOpWithSignature()
        );

        _sendUserOperation(_getUserOpWithSignature());
        assertTrue(optimismAccount.isOwnerAddress(newOwner));
    }

    function test_reverts_whenSelectorNotApproved() public {
        bytes4 selector = CoinbaseSmartWallet.execute.selector;
        assertFalse(account.canSkipChainIdValidation(selector));
        bytes memory restrictedSelectorCalldata = abi.encodeWithSelector(
            selector,
            ""
        );
        calls.push(restrictedSelectorCalldata);
        vm.prank(address(entryPoint));
        vm.expectRevert(
            abi.encodeWithSelector(
                CoinbaseSmartWallet.SelectorNotAllowed.selector,
                CoinbaseSmartWallet.execute.selector
            )
        );
        account.executeWithoutChainIdValidation(calls);
    }

    function test_reverts_whenOneSelectorNotApproved() public {
        bytes4 badSelector = CoinbaseSmartWallet.execute.selector;
        bytes4 goodSelector = MultiOwnable.addOwnerAddress.selector;
        assertFalse(account.canSkipChainIdValidation(badSelector));
        assertTrue(account.canSkipChainIdValidation(goodSelector));
        calls.push(abi.encodeWithSelector(badSelector, ""));
        address newOwner = address(6);
        assertFalse(account.isOwnerAddress(newOwner));
        calls.push(abi.encodeWithSelector(goodSelector, newOwner));
        vm.prank(address(entryPoint));
        vm.expectRevert(
            abi.encodeWithSelector(
                CoinbaseSmartWallet.SelectorNotAllowed.selector,
                CoinbaseSmartWallet.execute.selector
            )
        );
        account.executeWithoutChainIdValidation(calls);
    }

    function test_reverts_whenOneCallReverts() public {
        bytes4 selector = MultiOwnable.addOwnerAddress.selector;
        assertTrue(account.canSkipChainIdValidation(selector));
        address newOwner = address(6);
        assertFalse(account.isOwnerAddress(newOwner));
        calls.push(abi.encodeWithSelector(selector, newOwner));
        calls.push(abi.encodeWithSelector(selector, newOwner));
        userOpCalldata = abi.encodeWithSelector(
            CoinbaseSmartWallet.executeWithoutChainIdValidation.selector,
            calls
        );
        vm.prank(address(entryPoint));
        vm.expectRevert();
        account.executeWithoutChainIdValidation(calls);
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
