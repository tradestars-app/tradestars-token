// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import { ManagerBase, IERC20 } from "./ManagerBase.sol";

interface AToken {
    function redeem(uint256) external;
}

interface LendingPool {
    function deposit(address, uint256, uint16) payable external;
}

contract ManagerAave is ManagerBase {

    /// mainnet address
    address lendingPool = address(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);
    address lendingPoolCore = address(0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3);

    function _depositEth(
        address, // _token
        uint256 _amount
    )
        internal override
    {
        LendingPool(lendingPool).deposit{
            value: _amount,
            gas: 250000
        } (
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
            _amount,
            0 /// ref code
        );
    }

    function _deposit(
        address _token,
        uint256 _amount
    )
        internal override
    {
        // Approve transfer on the ERC20 contract
        IERC20(_token).safeIncreaseAllowance(
            lendingPoolCore,
            _amount
        );

        LendingPool(lendingPool).deposit(
            _token,
            _amount,
            0 /// ref code
        );
    }

    function _redeem(
        address _token,
        uint256 _amount
    )
        internal override
    {
        address mappedToken = getMappedToken(_token);
        AToken(mappedToken).redeem(_amount);
    }
}
