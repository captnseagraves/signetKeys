// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {UserOperation} from "account-abstraction/interfaces/UserOperation.sol";
import {UUPSUpgradeable} from "solady/utils/UUPSUpgradeable.sol";
import {Ownable} from "@openzeppelin/contracts/access/OwnableUpgradeable.sol";

import {ISignetEmitter} from "./ISignetEmitter.sol";

// TODO: add ownable and upgradable
// TODO: comments and clean up

contract SignetEmitter is ISignetEmitter, UUPSUpgradeable, OwnableUpgradeable {
    // constructor() Ownable(initialOwner) {
    //     OwnableUpgradeable.__Ownable_init();
    // }

    function initialize(address initialOwner) {
        OwnableUpgradeable.__Ownable_init(initialOwner);
    }

    function emitActionRequest(
        address sender,
        UserOperation calldata userOp
    ) external {
        emit SignetActionRequest(sender, userOp);
    }
}
