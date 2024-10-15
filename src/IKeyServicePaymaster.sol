// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IKeyServicePaymaster {
    function addFactory(address factory) external;
    function deposit() external payable;
    function owner() external view returns (address);
}
