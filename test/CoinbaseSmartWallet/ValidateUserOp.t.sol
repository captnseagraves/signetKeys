// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "webauthn-sol/../test/Utils.sol";

import {MockEntryPoint} from "../mocks/MockEntryPoint.sol";
import "./SmartWalletTestBase.sol";

contract TestValidateUserOp is SmartWalletTestBase {
    struct _TestTemps {
        bytes32 userOpHash;
        address signer;
        uint256 privateKey;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 missingAccountFunds;
    }

    // /// we expect the system to emit an event with a userOp with signature included so it can be executed on other chains
    //     /// another test to include would be to prank a different chainId and execute a second time

    //     vm.expectEmit(true, true, false, false);
    //     emit ExecuteWithoutChainIdValidation(address(account), _getUserOpWithSignature());


    // test adapted from Solady
    function test_succeedsWithEOASigner() public {
        _TestTemps memory t;
        t.userOpHash = keccak256("123");
        t.signer = signer;
        t.privateKey = signerPrivateKey;
        (t.v, t.r, t.s) = vm.sign(t.privateKey, t.userOpHash);
        t.missingAccountFunds = 456;
        vm.deal(address(account), 1 ether);
        assertEq(address(account).balance, 1 ether);

        vm.etch(account.entryPoint(), address(new MockEntryPoint()).code);
        MockEntryPoint ep = MockEntryPoint(payable(account.entryPoint()));

        UserOperation memory userOp;
        // Success returns 0.
        userOp.signature = abi.encode(CoinbaseSmartWallet.SignatureWrapper(0, abi.encodePacked(t.r, t.s, t.v)));

        /// we expect the system to emit an event with a userOp with signature included so it can be executed on other chains
        /// another test to include would be to prank a different chainId and execute a second time
        if (bytes4(userOp.callData) == account.executeWithoutChainIdValidation.selector) {
            vm.expectEmit(true, true, false, false);
            emit KeyServiceActionRequest(address(account), _getUserOpWithSignature());

        }

        assertEq(ep.validateUserOp(address(account), userOp, t.userOpHash, t.missingAccountFunds), 0);
        assertEq(address(ep).balance, t.missingAccountFunds);
        // Failure returns 1.
        userOp.signature =
            abi.encode(CoinbaseSmartWallet.SignatureWrapper(0, abi.encodePacked(t.r, bytes32(uint256(t.s) ^ 1), t.v)));
        assertEq(ep.validateUserOp(address(account), userOp, t.userOpHash, t.missingAccountFunds), 1);
        assertEq(address(ep).balance, t.missingAccountFunds * 2);
        // Not entry point reverts.
        vm.expectRevert(MultiOwnable.Unauthorized.selector);
        account.validateUserOp(userOp, t.userOpHash, t.missingAccountFunds);
    }

    function test_succeedsWithPasskeySigner() public {
        _TestTemps memory t;
        t.userOpHash = keccak256("123");
        WebAuthnInfo memory webAuthn = Utils.getWebAuthnStruct(t.userOpHash);

        (bytes32 r, bytes32 s) = vm.signP256(passkeyPrivateKey, webAuthn.messageHash);
        s = bytes32(Utils.normalizeS(uint256(s)));
        bytes memory sig = abi.encode(
            CoinbaseSmartWallet.SignatureWrapper({
                ownerIndex: 1,
                signatureData: abi.encode(
                    WebAuthn.WebAuthnAuth({
                        authenticatorData: webAuthn.authenticatorData,
                        clientDataJSON: webAuthn.clientDataJSON,
                        typeIndex: 1,
                        challengeIndex: 23,
                        r: uint256(r),
                        s: uint256(s)
                    })
                )
            })
        );

        vm.etch(account.entryPoint(), address(new MockEntryPoint()).code);
        MockEntryPoint ep = MockEntryPoint(payable(account.entryPoint()));

        UserOperation memory userOp;
        // Success returns 0.
        userOp.signature = sig;
        assertEq(ep.validateUserOp(address(account), userOp, t.userOpHash, t.missingAccountFunds), 0);
    }

    function test_reverts_whenSelectorInvalidForReplayableNonceKey() public {
        UserOperation memory userOp;
        userOp.nonce = 0;
        userOp.callData = abi.encodeWithSelector(CoinbaseSmartWallet.executeWithoutChainIdValidation.selector, "");
        vm.startPrank(account.entryPoint());
        vm.expectRevert(abi.encodeWithSelector(CoinbaseSmartWallet.InvalidNonceKey.selector, 0));
        account.validateUserOp(userOp, "", 0);
    }

    function test_reverts_whenReplayableNonceKeyInvalidForSelector() public {
        UserOperation memory userOp;
        userOp.nonce = account.REPLAYABLE_NONCE_KEY() << 64;
        userOp.callData = abi.encodeWithSelector(CoinbaseSmartWallet.execute.selector, "");
        vm.startPrank(account.entryPoint());
        vm.expectRevert(
            abi.encodeWithSelector(CoinbaseSmartWallet.InvalidNonceKey.selector, account.REPLAYABLE_NONCE_KEY())
        );
        account.validateUserOp(userOp, "", 0);
    }
}
