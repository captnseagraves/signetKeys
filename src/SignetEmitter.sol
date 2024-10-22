// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {UserOperation} from "account-abstraction/interfaces/UserOperation.sol";

import {ISignetEmitter} from "./ISignetEmitter.sol";

import {console} from "forge-std/console.sol";
// TODO: add ownable and upgradable
// TODO: comments and clean up

contract SignetEmitter is ISignetEmitter {
    function emitActionRequest(
        address sender,
        UserOperation calldata userOp
    ) external {
        emit SignetActionRequest(sender, userOp);
    }
}
