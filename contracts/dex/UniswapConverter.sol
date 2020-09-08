// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "./IConverter.sol";
import "./IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract UniswapConverter is IConverter {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IUniswapV2Router02 public immutable uniswapV2Router;

    /**
     * @param _uniswapV2Router UniswapV2Router02 address.
     */
    constructor(address _uniswapV2Router) public {
        uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
    }

    function swapEthToToken(
        IERC20 _dstToken,
        uint256 _maxDstAmount,
        address _beneficiary
    )
        external payable override returns (uint256 dstAmount, uint256 srcReminder)
    {
        address[] memory path = new address[](2);

        path[0] = uniswapV2Router.WETH();
        path[1] = address(_dstToken);

        uint256 srcAmount = msg.value;

        uint256[] memory amounts = uniswapV2Router.swapExactETHForTokens{
            value: srcAmount
        } (
            _maxDstAmount,
            path,
            _beneficiary,
            block.timestamp
        );

        // Fill return vars
        dstAmount = amounts[1];
        srcReminder = srcAmount.sub(amounts[0]);
    }

    function swapTokenToToken(
        IERC20 _srcToken,
        IERC20 _dstToken,
        uint256 _srcAmount,
        uint256 _maxDstAmount,
        address _beneficiary
    )
        external override returns (uint256 dstAmount, uint256 srcRemainder)
    {
        // Get Tokens from caller and aprove exchange
        _srcToken.safeTransferFrom(msg.sender, address(this), _srcAmount);
        _srcToken.safeIncreaseAllowance(address(uniswapV2Router), _srcAmount);

        address[] memory path = new address[](2);

        path[0] = address(_srcToken);
        path[1] = address(_dstToken);

        uint256[] memory amounts = uniswapV2Router.swapExactTokensForTokens(
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
