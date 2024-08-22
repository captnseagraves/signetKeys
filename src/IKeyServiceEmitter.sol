// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IKeyServiceEmitter {

 /// EVENTS

// userOp will be updated on each chain with paymaster data so we do not include missingAccountFunds in event
event ExecuteWithoutChainIdValidation(address indexed sender, UserOperation userOp);

function emitAction(address sender, UserOperation userOp) external returns (bool success);
}