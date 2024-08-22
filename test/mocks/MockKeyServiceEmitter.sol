// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {UserOperation} from "account-abstraction/interfaces/UserOperation.sol";

import {IKeyServiceEmitter} from "../../src/IKeyServiceEmitter.sol";

contract MockKeyServiceEmitter is IKeyServiceEmitter {

    function emitActionRequest(address sender, UserOperation calldata userOp) external {
        emit KeyServiceActionRequest(sender, userOp);
    }
}
