// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {UserOperation} from "account-abstraction/interfaces/UserOperation.sol";

import {IKeyServiceEmitter} from "./IKeyServiceEmitter.sol";

import {console} from "forge-std/console.sol";

contract KeyServiceEmitter is IKeyServiceEmitter {
    /// the purpose of this contract is to be deployed via create2
    /// and create a single contract for relayers to listen to for events

    /// EVENTS

    /// FUNCTIONS

    function emitActionRequest(
        address sender,
        UserOperation calldata userOp
    ) external {
        console.log("tag");

        // emit KeyServiceActionRequest(sender, userOp);
    }
}

// it would be nice to have a gas estimation function for all of the chains being updated
// it would need to be an offchain oracle provided by the relayer service
// perhaps there is a balance that anyone can deposit into, such as Base for an address they want to update,
// and the relayer service can withdraw from that balance to pay for gas on all chains

// relayers can listen to events on other chains and provide a signature that txns have been executed
// then relayers can withdraw their gas refund
// this is where you might want an AVS so that relayers could be slashed if they provide a signature that is nefarious
// or if they do not execute a txn within a certain time period

// if you added a 'pause' var and a withdraw function to the wallet, then you could pause the wallet during an external
// execution
// and allow the relayer to withdraw the gas refund or other value transferred

// paymasters are assumed to be funded by the wallet UI provider
// otherwise we need to find a way for the canon chain to pay the gas of all external chains

// this contract should probably be ownable and upgradable
// another version of this service could:
// 1. take a subscription from wallet providers and charge a $1/month per wallet fee, and a small fee on each txn for gas

// The real structure is to process any transaction given a chainId and charge a gasFee
