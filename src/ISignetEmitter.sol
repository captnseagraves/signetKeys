// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {UserOperation} from "account-abstraction/interfaces/UserOperation.sol";

interface ISignetEmitter {
    /// EVENTS

    // userOp will be updated on each chain with paymaster data so we do not include missingAccountFunds in event
    event SignetActionRequest(
        address indexed sender,
        UserOperation userOp,
        address deploymentFactoryAddress,
        bytes[] deploymentOwners,
        uint256 deploymentNonce
    );

    function emitActionRequest(
        address sender,
        UserOperation calldata userOp,
        address deploymentFactoryAddress,
        bytes[] memory deploymentOwners,
        uint256 deploymentNonce
    ) external;
}
