// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../eip712/ITransferWithSig.sol";

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
     * @dev The exit() sends tokens to layer 2 withdrawer(),
     *  we need to get those tokens here to convert sTSX into paymentToken.
     *  We'are calling this method with a eip712 token transfer signature for that purpose.
     *
     * @param _tokenAmount sigTransfer tokenAmount
     * @param _expiration sigTransfer expiration
     * @param _orderId sigTransfer orderId
     * @param _orderSignature signedTypedData signature
     * @param _paymentToken final payment token ERC20 address
     * @param _burnProof from withdraw() inclusion in mainnet
     */
    function withdraw(
        uint256 _tokenAmount,
        uint256 _expiration,
        bytes32 _orderId,
        bytes calldata _orderSignature,
        IERC20 _paymentToken,
        bytes calldata _burnProof
    )
        external
    {
        uint256 bTokenBalance = bridgeableToken.balanceOf(address(this));

        // Get tokens from L2 bridge
        IRootChainManager(posBridge).exit(_burnProof);

        // Transfer sTSX amount from L2 burner's address
        //  to this contract using EIP712 signature

        ITransferWithSig(address(bridgeableToken)).transferWithSig(
            _orderSignature,
            _tokenAmount,
            keccak256(
                abi.encodePacked(_orderId, address(bridgeableToken), _tokenAmount)
            ),
            _expiration,
            address(this)
        );

        // Check bridgeableToken balance from exit
        uint256 withdrawAmount = bridgeableToken
            .balanceOf(address(this))
            .sub(bTokenBalance);

        require(withdrawAmount > 0, "Cashier: withdrawAmount invalid");

        emit BridgeExit(msg.sender, withdrawAmount);

        bridgeableToken.burn(withdrawAmount);

        /// If user asked same coin as reserve, send directly
        if (_paymentToken == reserveToken) {
            reserveToken.safeTransfer(msg.sender, withdrawAmount);

        /// reserve <> token conversion
        } else {
            bytes memory r = address(swapManager).callfn(
                abi.encodeWithSelector(
                    ISwapManager.swapTokenToToken.selector,
                    // args
                    reserveToken,
                    _paymentToken,
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
        uint256 _depositAmount,
        address _addrTo
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

        _posDeposit(bridgeableToken, _addrTo, _depositAmount);
    }

    /**
     * @dev deposit eth
     */
    function deposit(address _addrTo) external payable {
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

        _posDeposit(bridgeableToken, _addrTo, _depositAmount);
    }

    /**
     * @dev Clears allowance and calls POS bridge depositFor()
     *  _erc20Token should be already approved to be bridged.
     *
     * @param _erc20Token to deposit
     * @param _toAddr user address to send tokens to
     * @param _amount amount to deposit
     */
    function _posDeposit(
        IBridgableToken _erc20Token,
        address _toAddr,
        uint256 _amount
    )
        private
    {
        // mint 1:1 and deposit
        _erc20Token.mint(address(this), _amount);

        // Call pos bridge depositFor.
        IRootChainManager(posBridge).depositFor(
            _toAddr,
            address(_erc20Token),
            abi.encode(_amount)
        );

        emit BridgeDeposit(_toAddr, _amount);
    }
}
