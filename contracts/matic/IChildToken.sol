
// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;


interface IChildToken {
    function withdraw(uint256 amount) external;
    function deposit(address user, bytes calldata depositData) external;
}
