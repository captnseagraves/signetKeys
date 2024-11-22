// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {UserOperation} from "account-abstraction/interfaces/UserOperation.sol";
import {UUPSUpgradeable} from "solady/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {ISignetEmitter} from "./ISignetEmitter.sol";

// TODO: add ownable and upgradable
// TODO: comments and clean up

contract SignetEmitter is ISignetEmitter, UUPSUpgradeable, OwnableUpgradeable {
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public {
        require(
            initialOwner != address(0),
            "Initial owner cannot be zero address"
        );
        __Ownable_init(initialOwner); // Initialize the Ownable contract
    }

    function emitActionRequest(
        address sender,
        UserOperation calldata userOp,
        address deploymentFactoryAddress,
        bytes[] memory deploymentOwners,
        uint256 deploymentNonce
    ) external {
        emit SignetActionRequest(
            sender,
            userOp,
            deploymentFactoryAddress,
            deploymentOwners,
            deploymentNonce
        );
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal view override onlyOwner {
        require(
            newImplementation != address(0),
            "New implementation cannot be zero address"
        );
        require(
            newImplementation.code.length > 0,
            "New implementation must be a contract"
        );
    }
}
