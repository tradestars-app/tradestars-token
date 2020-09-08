// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../dex/IConverter.sol";
import "../defi/IManager.sol";

import "../matic/IRootChainManager.sol";

interface IBridgable is IERC20 {
    function burn(uint256 _amount) external;
    function mint(address _to, uint256 _amount) external;
}

contract Cashier is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Amount is informed in bridgedToken currency
    event BridgeDeposit(address indexed wallet, uint256 amount);
    event BridgeExit(address indexed wallet, uint256 amount);

    IERC20 public reserveToken;
    IBridgable public bridgedToken;

    address public posBridge;

    IConverter public converter;
    IManager public reserveManager;

    constructor(
        address _bridge,
        address _reserve,
        address _bridgedToken,
        address _converter,
        address _manager
    )
        public
    {
        posBridge = _bridge;

        reserveToken = IERC20(_reserve);
        bridgedToken = IBridgable(_bridgedToken);

        /// sets converter
        setConverter(_converter);

        /// sets funds manager
        setManager(_manager);
    }

    /**
     * @dev Sets UniswapV2Converter to use
     */
    function setConverter(address _converter) public onlyOwner {
        require(_converter != address(0), "Cashier: invalid converter");
        converter = IConverter(_converter);
    }

    /**
     * @dev Sets ReserverManager to use
     */
    function setManager(address _manager) public onlyOwner {
        require(_manager != address(0), "Cashier: invalid fund manager");
        reserveManager = IManager(_manager);
    }

    /**
     * @dev redeem tokens
     */
    function withdraw(
        IERC20 _withdrawToken,
        bytes calldata _burnProof
    )
        external
    {
        uint256 balance = bridgedToken.balanceOf(address(this));

        // Get tokens from L2
        IRootChainManager(posBridge).exit(_burnProof);

        // Check bridgedToken balance from exit
        uint256 newBalance = bridgedToken.balanceOf(address(this));
        uint256 redeemableAmount = newBalance.sub(balance);

        require(redeemableAmount > 0, "Cashier: redeemableAmount invalid");

        emit BridgeExit(msg.sender, redeemableAmount);

        /// We burn 1:1 pegged depositable
        bridgedToken.burn(redeemableAmount);

        /// Change mapped tokens for reserve
        reserveManager.redeem(
            address(reserveToken),
            redeemableAmount
        );

        /// If user asked same coin as reserve, send directly
        if (_withdrawToken == reserveToken) {
            reserveToken.safeTransfer(msg.sender, redeemableAmount);

        /// or use uniswap api to perform reserve <> token conversion
        } else {
            (, uint256 swapReminder) = converter.swapTokenToToken(
                reserveToken,
                _withdrawToken,
                redeemableAmount,
                0, /// maxDstAmount ??
                msg.sender /// _beneficiary
            );
            require(swapReminder == 0, "Cashier :: reminder in tx");
        }
    }

    /**
     * @dev deposit tokens
     */
    function deposit(
        IERC20 _depositToken,
        uint256 _depositAmount
    )
        external
    {
        // Get the starting value for the reserve
        uint256 initialReserve = reserveToken.balanceOf(address(this));

        /// transfer user tokens into our vault
        _depositToken.safeTransferFrom(
            msg.sender,
            address(this),
            _depositAmount
        );

        /// Call uniswap api to perform token <> reserve conversion
        if (_depositToken != reserveToken) {

            /// Allow converter
            _depositToken.safeIncreaseAllowance(
                address(converter),
                _depositAmount
            );

            (, uint256 reminder) = converter.swapTokenToToken(
                _depositToken,
                reserveToken,
                _depositAmount,
                0, /// maxDstAmount ??
                address(this) /// _beneficiary
            );
            require(reminder == 0, "Cashier :: reminder tx");
        }

        // Get reserveToken depositableAmount
        uint256 newBalance = reserveToken.balanceOf(address(this));
        uint256 depositableAmount = newBalance.sub(initialReserve);

        _depositReserve(depositableAmount, msg.sender);
    }

    /**
     * @dev deposit eth
     */
    function deposit() external payable {

        // Get the starting value for the reserve
        uint256 initialReserve = reserveToken.balanceOf(
            address(this)
        );

        (, uint256 reminder) = converter.swapEthToToken{
            value: msg.value
        } (
            reserveToken,
            0, /// maxDstAmount
            address(this) /// _beneficiary
        );
        require(reminder == 0, "Cashier :: reminder tx");

        // Get reserveToken depositableAmount
        uint256 newBalance = reserveToken.balanceOf(address(this));
        uint256 depositableAmount = newBalance.sub(initialReserve);

        _depositReserve(depositableAmount, msg.sender);
    }

    /**
     * @dev This intermal function invest the reserveToken in AAVE,
     *  mints a 1:1 pegged bridgedToken and deposit that into Matic L2 bridge
     * @param _amount amount to deposit
     */
    function _depositReserve(
        uint256 _amount,
        address _beneficiary
    )
        private
    {
        /// allow manager to move _amount reserve tokens
        reserveToken.safeIncreaseAllowance(
            address(reserveManager),
            _amount
        );

        /// Swap reserve for <> aTokens
        reserveManager.deposit(
            address(reserveToken),
            _amount
        );

        /// We mint 1:1 pegged depositable <> aTokens
        bridgedToken.mint(address(this), _amount);

        /// and transfer depositable into the L2 bridge.
        _posDeposit(
            bridgedToken,
            _beneficiary,
            _amount,
            posBridge
        );
    }

    /**
     * @dev Clears allowance and calls POS bridge depositFor()
     * @param _toAddr user address to deposit
     * @param _amount amount to deposit
     * @param _bridge address of the plasma calling contract
     */
    function _posDeposit(
        IERC20 _erc20Token,
        address _toAddr,
        uint256 _amount,
        address _bridge
    )
        private
    {
        require(_amount > 0, "invalid amount");

        // Allowance should be 0 before the call or fails
        _erc20Token.safeApprove(_bridge, _amount);

        /// Call pos bridge depositFor
        IRootChainManager(_bridge).depositFor(
            _toAddr,
            address(_erc20Token),
            abi.encode(_amount)
        );

        emit BridgeDeposit(_toAddr, _amount);
    }
}
