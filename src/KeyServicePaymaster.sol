// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BasePaymaster} from "@account-abstraction/core/BasePaymaster.sol";

import {IKeyServiceEmitter} from "./IKeyServiceEmitter.sol";

import {console} from "forge-std/console.sol";

contract KeyServicePaymaster is BasePaymaster, Ownable2Step {
    using UserOperationLib for UserOperation;

    mapping(address => bool) public validFactories;

    function addFactory(address factory) public onlyOwner {
        validFactories[factory] = true;
    }

    function removeFactory(address factory) public onlyOwner {
        validFactories[factory] = false;
    }

    function validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32,
        uint256
    )
        external
        pure
        override
        returns (bytes memory context, uint256 validationData)
    {
        context = new bytes(0);
        validationData = 0;

        if (!isValidFunction(selector)) {
            revert SelectorNotAllowed(selector);
        }

        // check that the paymaster is funded
        // check that the userOp is for a valid function selector
        // checkthat the userOp is coming from a valid wallet
        //

        if (
            bytes4(userOp.callData) ==
            this.executeWithoutChainIdValidation.selector
        ) {
            emitKeyServiceActionRequest = true;
            userOpHash = getUserOpHashWithoutChainId(userOp);

            console.log(
                "emitKeyServiceActionRequest",
                emitKeyServiceActionRequest
            );

            if (key != REPLAYABLE_NONCE_KEY) {
                revert InvalidNonceKey(key);
            }
        } else {
            if (key == REPLAYABLE_NONCE_KEY) {
                console.log("not it");
                revert InvalidNonceKey(key);
            }
        }
    }

    function postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost
    ) external override {}

    /// @notice Returns whether `functionSelector` can be paid for by the paymaster.
    ///
    /// @param functionSelector The function selector to check.
    ////
    /// @return `true` is the function selector is allowed by paymaster, else `false`.
    function isValidFunction(
        bytes4 functionSelector
    ) public pure returns (bool) {
        if (
            functionSelector == MultiOwnable.addOwnerPublicKey.selector ||
            functionSelector == MultiOwnable.addOwnerAddress.selector ||
            functionSelector == MultiOwnable.removeOwnerAtIndex.selector ||
            functionSelector == MultiOwnable.removeLastOwner.selector ||
            functionSelector == UUPSUpgradeable.upgradeToAndCall.selector
        ) {
            return true;
        }
        return false;
    }
}

// could validate based on a signature the wallet factory that an address is deployed from
// on deployment, factory would sign a simple message (wallet address), lineageSignature, that could be verified by the paymaster
// paymaster would track whether that factory has been approved by owner.

// could also validate based on nonce and create2 style deployment scheme, if the allet is tracking the nonce, etc but not sure there is robust enugh context
