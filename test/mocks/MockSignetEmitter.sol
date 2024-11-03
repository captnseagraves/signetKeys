// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {UserOperation} from "account-abstraction/interfaces/UserOperation.sol";

import {ISignetEmitter} from "../../src/ISignetEmitter.sol";

contract MockSignetEmitter is ISignetEmitter {
    function emitActionRequest(
        address sender,
        UserOperation calldata userOp
    ) external {
        emit SignetActionRequest(sender, userOp);
    }
}