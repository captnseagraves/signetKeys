// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISignetSmartWallet {
    function REPLAYABLE_NONCE_KEY() external view returns (uint256);

    function deploymentFactoryAddress() external view returns (address);

    function getDeploymentOwners() external view returns (bytes[] memory);

    function deploymentNonce() external view returns (uint256);

    function executeWithoutChainIdValidation(
        bytes[] calldata calls
    ) external payable;
}
