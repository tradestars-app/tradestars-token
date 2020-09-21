// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../defi/ILendManager.sol";
import "../dex/ISwapManager.sol";

import "../matic/IRootChainManager.sol";
import "../matic/IBridgableToken.sol";

import "../libs/SafeDelegate.sol";


contract Cashier is Ownable {

    using SafeMath for uint256;
    using SafeDelegate for address;

    using SafeERC20 for IERC20;

    // Amount is informed in bridgeableToken currency
    event BridgeDeposit(address indexed wallet, uint256 amount);
    event BridgeExit(address indexed wallet, uint256 amount);
    event ReserveChanged(address indexed reserve);

    IERC20 public reserveToken;
    IBridgableToken public bridgeableToken;

    ISwapManager public swapManager;

    address public posBridge;

    constructor(
        address _bridge,
        address _reserve,
        address _bridgeableToken,
        address _swapManager
    )
        Ownable() public
    {
        posBridge = _bridge;

        reserveToken = IERC20(_reserve);
        bridgeableToken = IBridgableToken(_bridgeableToken);

        /// sets swapManager
        setSwapConverter(_swapManager);
    }

    /**
     * @dev Sets swap protocol api
     */
    function setSwapConverter(address _manager) public onlyOwner {
        require(_manager != address(0), "Cashier: invalid swap manager");
        swapManager = ISwapManager(_manager);
    }

    /**
     * @dev redeem ERC20
     */
    function withdraw(
        IERC20 _withdrawToken,
        bytes calldata _burnProof
    )
        external
    {
        uint256 bTokenBalance = bridgeableToken.balanceOf(address(this));

        // Get tokens from L2
        IRootChainManager(posBridge).exit(_burnProof);

        // Check bridgeableToken balance from exit
        uint256 withdrawAmount = bridgeableToken
            .balanceOf(address(this))
            .sub(bTokenBalance);

        require(withdrawAmount > 0, "Cashier: withdrawAmount invalid");

        emit BridgeExit(msg.sender, withdrawAmount);

        bridgeableToken.burn(withdrawAmount);

        /// If user asked same coin as reserve, send directly
        if (_withdrawToken == reserveToken) {
            reserveToken.safeTransfer(msg.sender, withdrawAmount);

        /// reserve <> token conversion
        } else {
            bytes memory r = address(swapManager).callfn(
                abi.encodeWithSelector(
                    ISwapManager.swapTokenToToken.selector,
                    // args
                    reserveToken,
                    _withdrawToken,
                    withdrawAmount,
                    0, /// maxDstAmount ??
                    msg.sender /// _beneficiary
                ),
                "Cashier :: swapTokenToToken()"
            );
            (, uint256 reminder) = abi.decode(r, (uint256,uint256));
            require(reminder == 0, "Cashier :: reminder swap tx");
        }
    }

    /**
     * @dev deposit using ERC20
     */
    function deposit(
        IERC20 _depositToken,
        uint256 _depositAmount
    )
        external
    {
        require(_depositAmount > 0, "Cashier :: invalid _depositAmount");

        // transfer user tokens
        _depositToken.safeTransferFrom(
            msg.sender,
            address(this),
            _depositAmount
        );

        // Call uniswap api to perform token <> reserve conversion
        if (_depositToken != reserveToken) {

            bytes memory r = address(swapManager).callfn(
                abi.encodeWithSelector(
                    ISwapManager.swapTokenToToken.selector,
                    // args
                    _depositToken,
                    reserveToken,
                    _depositAmount,
                    0, // maxDstAmount
                    address(this) // _beneficiary
                ),
                "Cashier :: swapManager swapTokenToToken.delegatecall()"
            );
            (uint256 amount, uint256 reminder) = abi.decode(r, (uint256,uint256));
            require(reminder == 0, "Cashier :: reminder tx");

            _depositAmount = amount;
        }

        // mint 1:1 and deposit
        bridgeableToken.mint(address(this), _depositAmount);

        _posDeposit(bridgeableToken, msg.sender, _depositAmount, posBridge);
    }

    /**
     * @dev deposit eth
     */
    function deposit() external payable {
        require(msg.value > 0, "Cashier :: invalid msg.value");

        bytes memory r = address(swapManager).callfn(
            abi.encodeWithSelector(
                swapManager.swapEthToToken.selector,
                // args
                msg.value,
                reserveToken,
                0,  // maxDstAmount
                address(this) // _beneficiary
            ),
            "Cashier :: swapEthToToken()"
        );

        (uint256 _depositAmount, uint256 reminder) = abi.decode(r, (uint256,uint256));
        require(reminder == 0, "Cashier :: reminder swap tx");

        // mint 1:1 and deposit
        bridgeableToken.mint(address(this), _depositAmount);

        _posDeposit(bridgeableToken, msg.sender, _depositAmount, posBridge);
    }

    /**
     * @dev Clears allowance and calls POS bridge depositFor()
     * @param _erc20Token to deposit
     * @param _toAddr user address to send tokens to
     * @param _amount amount to deposit
     * @param _bridge address of the POS bridge
     */
    function _posDeposit(
        IERC20 _erc20Token,
        address _toAddr,
        uint256 _amount,
        address _bridge
    )
        private
    {
        // Allowance should be 0 before the call or fails
        _erc20Token.safeApprove(_bridge, _amount);

        // /// Call pos bridge depositFor
        IRootChainManager(_bridge).depositFor(
            _toAddr,
            address(_erc20Token),
            abi.encode(_amount)
        );

        emit BridgeDeposit(_toAddr, _amount);
    }
}
