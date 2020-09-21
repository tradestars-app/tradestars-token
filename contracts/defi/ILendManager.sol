// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

interface ILendManager {
    function deposit(address _token, uint256 _amount) external payable;
    function redeem(address _mappedToken, uint256 _mappedAmount) external;
    function getMappedToken(address _token) external view returns (address);
    function setMappedToken(address _token, address _mappedToken) external;
}
