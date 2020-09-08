// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import { ManagerBase, IERC20 } from "./ManagerBase.sol";

interface CBaseToken {
    function exchangeRateCurrent() external returns (uint256);
    function supplyRatePerBlock() external returns (uint256);
    function redeem(uint256) external returns (uint256);
    function redeemUnderlying(uint256) external returns (uint256);
}

interface CErc20 is CBaseToken {
    function mint(uint256) external returns (uint256);
}

interface CEth is CBaseToken {
    function mint() external payable;
}

contract ManagerCompound is ManagerBase {

    function _depositEth(
        address _token,
        uint256 _amount
    )
        internal override
    {
        address _mappedToken = getMappedToken(_token);

        // Mint cEthers to caller, reverts on error
        CEth(_mappedToken).mint{ value: _amount, gas: 250000 }();
    }

    function _deposit(
        address _token,
        uint256 _amount
    )
        internal override
    {
        address _mappedToken = getMappedToken(_token);

        // Approve transfer on the ERC20 contract
        IERC20(_token).safeIncreaseAllowance(
            _mappedToken,
            _amount
        );

        // Mint cTokens
        uint256 mintResult = CErc20(_mappedToken).mint(_amount);
        require(mintResult == 0, "CManager: error CErc20.mint()");
    }

    function _redeem(
        address _token,
        uint256 _amount
    )
        internal override
    {
        address mappedToken = getMappedToken(_token);
        uint256 redeemResult = CBaseToken(mappedToken)
            .redeem(_amount);

        require(redeemResult == 0, "CManager: error calling redeem()");
    }
}
