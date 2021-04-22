// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract SwapProxyMock {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private constant tokenPairRatio = 3;

    function calcEthersPerToken(uint256 _input) public pure returns (uint256) {
        return _input.div(tokenPairRatio);
    }

    function calcTokensPerEther(uint256 _input) public pure returns (uint256) {
        return _input.mul(tokenPairRatio);
    }

    function calcTokensPerToken(uint256 _input) public pure returns (uint256) {
        return _input; // 1:1
    }

    function _swapEtherToToken(
        IERC20 _dstToken,
        uint256 _etherAmount,
        address _dstAddress
    )
        internal returns (uint256)
    {
        require(_etherAmount > 0, "SwapProxyMock: balance > 0 error");

        uint256 tokenAmount = calcTokensPerEther(_etherAmount);
        uint256 tokenBalance = _dstToken.balanceOf(address(this));

        require(
            tokenBalance >= tokenAmount,
            "SwapProxyMock: balance token/eth error"
        );

        _dstToken.safeTransfer(_dstAddress, tokenAmount);

        return tokenAmount;
    }

    function _swapTokenToEther(
        IERC20 _srcToken,
        uint256 _srcAmount,
        address payable _dstAddress,
        uint256 _maxDstAmount
    )
        internal returns (uint256)
    {
        uint256 etherAmount = calcEthersPerToken(_srcAmount);

        // if theres a limit in the dst amount, use that
        // to calculate
        if (_maxDstAmount > 0 && etherAmount > _maxDstAmount) {
            etherAmount = _maxDstAmount;
            _srcAmount = calcTokensPerEther(_maxDstAmount);
        }

        // Get tokens, send ethers to caller
        _srcToken.safeTransferFrom(msg.sender, address(this), _srcAmount);
        _dstAddress.transfer(etherAmount);

        return etherAmount;
    }

    function _swapTokenToToken(
        IERC20 _srcToken,
        IERC20 _dstToken,
        uint256 _srcAmount,
        address _dstAddress,
        uint256 _maxDstAmount
    )
        internal returns (uint256)
    {
        uint256 dstAmount = calcTokensPerToken(_srcAmount);

        // if theres a limit in the dst amount, use that
        // to calculate
        if (_maxDstAmount > 0 && dstAmount > _maxDstAmount) {
            dstAmount = _maxDstAmount;
            _srcAmount = calcTokensPerEther(_maxDstAmount);
        }

        // Get tokens, send ethers to caller
        _srcToken.safeTransferFrom(msg.sender, address(this), _srcAmount);
        _dstToken.safeTransfer(_dstAddress, dstAmount);

        return dstAmount;
    }

    receive() external payable {
        //
    }
}

// Mock called IUniswapV2Router02 methods
contract UniswapRouterMock is SwapProxyMock {

    function WETH() public pure returns (address) {
        return address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    }

    function getAmountsIn(
        uint _amountOut,
        address[] calldata _path
    )
        external pure returns (uint[] memory amounts)
    {
        uint256 amountIn =
            (_path[0] == WETH()) ? super.calcEthersPerToken(_amountOut):
            (_path[1] == WETH()) ? super.calcTokensPerEther(_amountOut):
            super.calcTokensPerToken(_amountOut);

        amounts = new uint[](1);
        amounts[0] = amountIn;
    }

    function swapExactTokensForETH(
        uint _amountIn,
        uint,
        address[] calldata _path,
        address _to,
        uint
    )
        external returns (uint[] memory amounts)
    {
        uint256 convertedTokens = _swapTokenToEther(
            IERC20(_path[0]),
            _amountIn,
            payable(_to),
            0
        );

        amounts = new uint[](2);

        amounts[0] = _amountIn;
        amounts[1] = convertedTokens;
    }

    function swapExactETHForTokens(
        uint,
        address[] calldata _path,
        address _to,
        uint
    )
        external payable returns (uint[] memory amounts)
    {
        uint256 convertedTokens = _swapEtherToToken(
            IERC20(_path[1]),
            msg.value,
            _to
        );

        amounts = new uint[](2);

        amounts[0] = msg.value;
        amounts[1] = convertedTokens;
    }

    ///

    function swapExactTokensForTokens(
        uint _amountIn,
        uint,
        address[] calldata _path,
        address _to,
        uint
    )
        external returns (uint[] memory amounts)
    {
        uint256 convertedTokens = _swapTokenToToken(
            IERC20(_path[0]),
            IERC20(_path[1]),
            _amountIn,
            payable(_to),
            0
        );

        amounts = new uint[](2);

        amounts[0] = _amountIn;
        amounts[1] = convertedTokens;
    }
}
