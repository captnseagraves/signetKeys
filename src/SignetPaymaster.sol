// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BasePaymaster} from "account-abstraction/core/BasePaymaster.sol";
import {UserOperation, UserOperationLib} from "account-abstraction/interfaces/UserOperation.sol";
import {UUPSUpgradeable} from "solady/utils/UUPSUpgradeable.sol";
import {MultiOwnable} from "./MultiOwnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";

import {ISignetEmitter} from "./ISignetEmitter.sol";
import {ISignetSmartWalletFactory} from "./ISignetSmartWalletFactory.sol";
import {ISignetSmartWallet} from "./ISignetSmartWallet.sol";


contract SignetPaymaster is BasePaymaster {
    mapping(address => bool) public validFactories;

    /// @notice Thrown when a call is passed to `executeWithoutChainIdValidation` that is not allowed by
    ///         `canSkipChainIdValidation`
    ///
    /// @param selector The selector of the call.
    error SelectorNotAllowed(bytes4 selector);

    error InvalidFactory(address factory);

    error InvalidAccount(address account);

    error InvalidEntryPoint();

    /// @notice Constructor for the paymaster setting the entrypoint, verifyingSigner and owner
    ///
    /// @param entryPoint the entrypoint contract
    constructor(
        IEntryPoint entryPoint,
        address initialOwner
    ) BasePaymaster(entryPoint) Ownable(initialOwner) {
        if (address(entryPoint).code.length == 0) {
            revert InvalidEntryPoint();
        }

        _transferOwnership(initialOwner);
    }

    function addFactory(address factory) public onlyOwner {
        validFactories[factory] = true;
    }

    function removeFactory(address factory) public onlyOwner {
        validFactories[factory] = false;
    }

    /// @dev Validates that the userOp is for a valid function selector and that the sender is a valid wallet
    ///      deployed by a valid factory.
    ///      This function can be generalized in the future for extensbility to other smart wallet clients.
    function _validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32,
        uint256
    )
        internal
        view
        override
        returns (bytes memory context, uint256 validationData)
    {
        context = new bytes(0);
        validationData = 0;

        if (
            bytes4(userOp.callData) !=
            ISignetSmartWallet.executeWithoutChainIdValidation.selector
        ) {
            revert SelectorNotAllowed(bytes4(userOp.callData));
        }

        bytes[] memory calls = abi.decode(userOp.callData[4:], (bytes[]));

        canExecuteViaPaymaster(calls);

        address factoryAddress = ISignetSmartWallet(userOp.sender)
            .deploymentFactoryAddress();

        bytes[] memory deploymentOwners = ISignetSmartWallet(userOp.sender)
            .getDeploymentOwners();

        uint256 deploymentNonce = ISignetSmartWallet(userOp.sender)
            .deploymentNonce();

        // check for a valid factory
        if (!validFactories[factoryAddress]) {
            revert InvalidFactory(factoryAddress);
        }

        // call factory.getAddress() to check deterministic account address
        address accountAddress = ISignetSmartWalletFactory(factoryAddress)
            .getAddress(deploymentOwners, deploymentNonce);

        // check that account was deployed by factory
        if (accountAddress != userOp.sender) {
            revert InvalidAccount(userOp.sender);
        }
    }

    function _postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost
    ) internal pure override {}

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

    /// @notice Executes `calls` on this account (i.e. self call).
    ///
    /// @dev Can only be called by the Entrypoint.
    /// @dev Reverts if the given call is not authorized to skip the chain ID validtion.
    /// @dev `validateUserOp()` will recompute the `userOpHash` without the chain ID before validating
    ///      it if the `UserOperation.calldata` is calling this function. This allows certain UserOperations
    ///      to be replayed for all accounts sharing the same address across chains. E.g. This may be
    ///      useful for syncing owner changes.
    ///
    /// @param calls An array of calldata to use for separate self calls.
    function canExecuteViaPaymaster(bytes[] memory calls) public pure {
        for (uint256 i; i < calls.length; i++) {
            bytes memory call = calls[i];
            bytes4 selector = bytes4(call);
            if (!isValidFunction(selector)) {
                revert SelectorNotAllowed(selector);
            }
        }
    }
}
