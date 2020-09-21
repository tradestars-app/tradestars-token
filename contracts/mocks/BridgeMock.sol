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
    )
        public
    {
        uint256 amount;

        assembly {
            amount := mload(add(_depositData, 32))
        }

        require(amount > 0, "BridgeMock: amount error");

        /// get tokens from caller.
        IERC20(_rootToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        require(
            IERC20(_rootToken).balanceOf(address(this)) >= amount,
            "BridgeMock: safeTransferFrom err"
        );
    }

    function depositERC20ForUser(
        address _rootToken,
        address, // _to,
        uint256 amount
    )
        public
    {

        /// get tokens from caller.
        IERC20(_rootToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    // this mock assumes we send the bridged token contract addr as param
    function exit(bytes memory _burnProof) public {
        address rootToken;
        address amount;

        assembly {
            rootToken := mload(add(_burnProof, 20))
        }

        uint256 totalAmount = IERC20(rootToken).balanceOf(address(this));

        IERC20(rootToken).safeTransfer(msg.sender, totalAmount);
    }
}
