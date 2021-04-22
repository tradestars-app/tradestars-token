// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC20MockBurnable } from "./ERC20Mock.sol";

contract LendingPoolMock {
    using SafeERC20 for IERC20;
    using SafeERC20 for ERC20MockBurnable;

    mapping (address => address) map;
    address token;

    constructor(address _token, address _mappedToken) public {
        token = _token;

        map[_mappedToken] = _token;
        map[_token] = _mappedToken;
    }

    function deposit(address _token, uint256 _amount, uint16) external {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        ERC20MockBurnable(map[token]).mint(msg.sender, _amount);
    }

    function redeem(uint256 _mappedAmount) external {
        ERC20MockBurnable(map[token]).burn(_mappedAmount);
        IERC20(token).safeTransfer(msg.sender, _mappedAmount);
    }
}
