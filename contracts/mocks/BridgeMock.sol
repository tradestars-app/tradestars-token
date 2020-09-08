// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "../matic/IRootChainManager.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";


contract BridgeMock {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function depositFor(
        address, // _user,
        address _rootToken,
        bytes memory _depositData
    ) public {
        uint256 amount;

        assembly {
            amount := mload(add(_depositData, add(0x20, 32)))
        }

        /// get tokens from caller.
        IERC20(_rootToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    function depositERC20ForUser(
        address _rootToken,
        address, // _to,
        uint256 amount
    ) public {

        /// get tokens from caller.
        IERC20(_rootToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    // function exit(bytes calldata _inputData) external {
    //     ///
    // };
}
