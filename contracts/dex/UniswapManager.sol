// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import { ISwapManager } from "./ISwapManager.sol";

interface IUniswapV2Router02 {

    function WETH() external pure returns (address);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract UniswapManager is ISwapManager {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public immutable uniswapV2Router;

    /**
     * @param _uniswapV2Router UniswapV2Router02 address.
     */
    constructor(address _uniswapV2Router) public {
        uniswapV2Router = _uniswapV2Router;
    }

    /**
     * Executes Eth <> token swap using the uniswapRouterV2.
     */
    function swapEthToToken(
        uint256 _srcAmount,
        IERC20 _dstToken,
        uint256 _maxDstAmount,
        address _beneficiary
    )
        external payable override returns (uint256 dstAmount, uint256 srcReminder)
    {
        address[] memory path = new address[](2);

        path[0] = IUniswapV2Router02(uniswapV2Router).WETH();
        path[1] = address(_dstToken);

        uint256[] memory amounts = IUniswapV2Router02(uniswapV2Router).swapExactETHForTokens{
            value: _srcAmount
        }(
            _maxDstAmount,
            path,
            _beneficiary,
            block.timestamp
        );

        // Fill return vars
        dstAmount = amounts[1];
        srcReminder = _srcAmount.sub(amounts[0]);
    }

    /**
     * Executes a token <> token swap using the uniswapRouterV2.
     */
    function swapTokenToToken(
        IERC20 _srcToken,
        IERC20 _dstToken,
        uint256 _srcAmount,
        uint256 _maxDstAmount,
        address _beneficiary
    )
        external override returns (uint256 dstAmount, uint256 srcRemainder)
    {
        IERC20(_srcToken).safeIncreaseAllowance(uniswapV2Router, _srcAmount);

        address[] memory path = new address[](2);

        path[0] = address(_srcToken);
        path[1] = address(_dstToken);

        uint256[] memory amounts = IUniswapV2Router02(uniswapV2Router).swapExactTokensForTokens(
            _srcAmount,
            _maxDstAmount,
            path,
            _beneficiary,
            block.timestamp
        );

        // Fill return vars
        dstAmount = amounts[1];
        srcRemainder = _srcAmount.sub(amounts[0]);
    }
}
