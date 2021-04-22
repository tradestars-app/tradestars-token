// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../matic/IRootChainManager.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


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
        uint256 amount = abi.decode(_depositData, (uint256));

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

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    // this mock assumes we send the bridged token contract addr as param
    function exit(bytes memory _burnProof) public {
        address rootToken = toAddress(_burnProof, 0);
        uint256 totalAmount = IERC20(rootToken).balanceOf(address(this));

        require(totalAmount > 0, "BridgeMock: _rootToken balance <= 0");

        IERC20(rootToken).safeTransfer(msg.sender, totalAmount);
    }
}
