// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BasePaymaster} from "account-abstraction/core/BasePaymaster.sol";
import {UserOperation, UserOperationLib} from "account-abstraction/interfaces/UserOperation.sol";
import {UUPSUpgradeable} from "solady/utils/UUPSUpgradeable.sol";
import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import {Ownable, Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

import {IKeyServiceEmitter} from "./IKeyServiceEmitter.sol";
import {ICoinbaseSmartWalletFactory} from "./ICoinbaseSmartWalletFactory.sol";
import {ICoinbaseSmartWallet} from "./ICoinbaseSmartWallet.sol";
import {CoinbaseSmartWallet} from "./CoinbaseSmartWallet.sol";
import {MultiOwnable} from "./MultiOwnable.sol";

import {console} from "forge-std/console.sol";

contract KeyServicePaymaster is BasePaymaster {
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
    ) BasePaymaster(entryPoint) Ownable2Step() {
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

    function _validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    ) internal override returns (bytes memory context, uint256 validationData) {
        context = new bytes(0);
        validationData = 0;

        // check that the userOp is coming from a valid wallet
        // check that the wallet was deployed by a valid factory

        // check that the userOp is for a valid function selector
        if (
            bytes4(userOp.callData) !=
            CoinbaseSmartWallet.executeWithoutChainIdValidation.selector
        ) {
            revert SelectorNotAllowed(bytes4(userOp.callData));
        }

        address factoryAddress = ICoinbaseSmartWallet(userOp.sender)
            .deploymentFactoryAddress();

        // owners may be a problematic variables name once ownable is implemented

        bytes[] memory owners = ICoinbaseSmartWallet(userOp.sender)
            .deploymentOwners();
        uint256 nonce = ICoinbaseSmartWallet(userOp.sender).deploymentNonce();

        // check for a valid factory
        if (!validFactories[factoryAddress]) {
            revert InvalidFactory(factoryAddress);
        }

        // call factory.getAddress() to check deterministic account address
        address accountAddress = ICoinbaseSmartWalletFactory(factoryAddress)
            .getAddress(owners, nonce);

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
}

// could validate based on a signature the wallet factory that an address is deployed from
// on deployment, factory would sign a simple message (wallet address), lineageSignature, that could be verified by the paymaster
// paymaster would track whether that factory has been approved by owner.

// could also validate based on nonce and create2 style deployment scheme, if the allet is tracking the nonce, etc but not sure there is robust enugh context
