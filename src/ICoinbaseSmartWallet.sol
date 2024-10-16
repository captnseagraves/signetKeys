// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICoinbaseSmartWallet {
    function REPLAYABLE_NONCE_KEY() external view returns (uint256);

    function deploymentFactoryAddress() external view returns (address);

    function deploymentOwners() external view returns (bytes[] memory);

    function getDeploymentOwners() external view returns (bytes[] memory);

    function deploymentNonce() external view returns (uint256);

    function isOwnerAddress(address owner) external view returns (bool);
}
