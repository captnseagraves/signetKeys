// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@account-abstraction/contracts/interfaces/IPaymaster.sol";

import {IKeyServiceEmitter} from "./IKeyServiceEmitter.sol";

import {console} from "forge-std/console.sol";

contract KeyServicePaymaster is IPaymaster {
    /// FUNCTIONS
    // 1.

    function validatePaymasterUserOp(
        UserOperation calldata,
        bytes32,
        uint256
    )
        external
        pure
        override
        returns (bytes memory context, uint256 validationData)
    {
        context = new bytes(0);
        validationData = 0;
    }

    function postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost
    ) external override {}
}
