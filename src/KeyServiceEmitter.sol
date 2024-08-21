// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {UserOperation, UserOperationLib} from "account-abstraction/interfaces/UserOperation.sol";


contract KeyServiceEmitter {

    /// the purpose of this contract is to be deployed via create2 
    /// and create a single contract for relayers to listen to for events

    /// STATE VARIABLES

    /// EVENTS

    // userOp will be updated on each chain with paymaster data so we do not include missingAccountFunds in event
    event ExecuteWithoutChainIdValidation(address indexed sender, UserOperation userOp);

    /// Errors

    /// FUNCTIONS

}

// it would be nice to have a gas estimation function for all of the chains being updated
// it would need to be an offchain oracle provided by the relayer service
// perhaps there is a balance that anyone can deposit into, such as Base for an address they want to update, 
// and the relayer service can withdraw from that balance to pay for gas on all chains

// relayers can listen to events on other chains and provide a signature that txns have been executed
// then relayers can withdraw their gas refund
// this is where you might want an AVS so that relayers could be slashed if they provide a signature that is nefarious
// or if they do not execute a txn within a certain time period

// if you added a 'pause' var and a withdraw function to the wallet, then you could pause the wallet during an external execution 
// and allow the relayer to withdraw the gas refund or other value transferred

// paymasters are assumed to be funded by the wallet UI provider
// otherwise we need to find a way for the canon chain to pay the gas of all external chains
