// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import { LendManager } from "./LendManager.sol";

interface AToken {
    function redeem(uint256) external;
}

interface LendingPool {
    function deposit(address, uint256, uint16) payable external;
}

contract AaveManager is LendManager {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address constant AAVE_ETH_ADDR = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// AAVE addresses
    address public immutable lendingPool;// = address(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);
    address public immutable lendingPoolCore;// = address(0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3);

    constructor(
        address _aaveLendingPool,
        address _aaveLendingPoolCore
    )
        public
    {
        lendingPool = _aaveLendingPool;
        lendingPoolCore = _aaveLendingPoolCore;
    }

    function deposit(
        address _token,
        uint256 _amount
    )
        external payable override
    {
        IERC20(_token).safeIncreaseAllowance(lendingPoolCore, _amount);
        LendingPool(lendingPool).deposit(
            _token,
            _amount,
            0 // ref code
        );
    }

    function redeem(
        address _mappedToken,
        uint256 _mappedAmount
    )
        external override
    {
        AToken(_mappedToken).redeem(_mappedAmount);
    }
}
