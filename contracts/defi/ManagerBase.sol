// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "./IManager.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";


abstract contract ManagerBase is Ownable, IManager {

    using SafeERC20 for IERC20;

    // ropsten
    mapping (address => address) private tokensMap;

    function setTokenPair(address _token, address _mappedToken) public onlyOwner {
        tokensMap[_token] = _mappedToken;
    }

    function getMappedToken(address _token) public view override returns (address) {
        address mappedToken = tokensMap[_token];

        require(
            mappedToken != address(0),
            "ManagerBase: address not mapped"
        );

        return mappedToken;
    }

    function depositEth() external override payable {
        _depositEth(address(0), msg.value);
    }

    function deposit(address _token, uint256 _amount) external override {
        _deposit(_token, _amount);
    }

    function redeem(address _token, uint256 _amount) external override {
        require(_token != address(0), 'ManagerBase: _token invalid');
        _redeem(_token, _amount);
    }

    function _depositEth(address _token, uint256 _amount) internal virtual;
    function _deposit(address _token, uint256 _amount) internal virtual;
    function _redeem(address _token, uint256 _amount) internal virtual;
}
