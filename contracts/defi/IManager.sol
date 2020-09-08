
// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

interface IManager {
    function getMappedToken(address _token) external view returns (address);
    function depositEth() external payable;
    function deposit(address _token, uint256 _amount) external;
    function redeem(address _token, uint256 _amount) external;
}
