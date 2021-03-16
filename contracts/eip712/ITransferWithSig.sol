// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

// Simple
interface ITransferWithSig {
    function transferWithSig(
        bytes calldata sig,
        uint256 tokenIdOrAmount,
        bytes32 data,
        uint256 expiration,
        address to
    ) external returns (address);
}