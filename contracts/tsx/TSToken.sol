// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Pausable.sol";

interface IPlasmaRoot {
    function depositERC20ForUser(address _token, address _user, uint256 _amount) external;
}

contract TSToken is Initializable, Ownable, ERC20Pausable {
    event PlasmaDeposit(address indexed wallet, uint256 amount);
    event Redeemed(address indexed user, uint256 amount);

    /// Token details
    string public constant NAME = "TradeStars TSX Utility Coin";
    string public constant SYMBOL = "TSX";
    uint8 public constant DECIMALS = 18;

    /// Used to keep track of referrals
    struct ReferralInfo {
        uint256 qualifiedNonce;
        uint256 accumulatedAmount;
    }

    mapping(address => ReferralInfo) private referralsInfo;

    /// allowed address to send tokens from referral bonus
    address private referralManager;

    /// to easy keep tracking of burns
    uint256 public tokensBurned;

    /**
     * @dev Throws if called by any account other than the manger.
     */
    modifier onlyReferralManager() {
        require(msg.sender == referralManager, "msg.sender is not referralManager");
        _;
    }

    constructor() Ownable() ERC20(NAME, SYMBOL) public { }

    /**
     * Initializer function.
     */
    function initialize() public initializer { }

    /**
     * @dev Sets the referral contract address. Can only be called by admin
     * @param _referralManager address
     */
    function setReferralManager(address _referralManager) external onlyOwner {
        referralManager = _referralManager;
    }

    /**
     * @dev Mints a specific amount of tokens.
     * @param _to The amount of token to be minted.
     * @param _value The amount of token to be minted.
     */
    function mint(address _to, uint256 _value) external onlyOwner {
        _mint(_to, _value);
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param _amount The amount of token to be burned.
     */
    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);

        tokensBurned = tokensBurned.add(_amount);
    }

    /**
     * @dev Burns a specific amount of tokens from the target address and decrements allowance
     * @param _account address The address which you want to send tokens from
     * @param _amount uint256 The amount of token to be burned
     */
    function burnFrom(address _account, uint256 _amount) public virtual {
        uint256 decreasedAllowance = allowance(_account, msg.sender).sub(_amount, "ERC20: burn amount exceeds allowance");

        _approve(_account, msg.sender, decreasedAllowance);
        _burn(_account, _amount);

        tokensBurned = tokensBurned.add(_amount);
    }

    /**
     * @dev Returns referral info for caller
     */
    function getReferralInfo(address user) external view returns (uint256 nonce, uint256 amount) {
        nonce = referralsInfo[user].qualifiedNonce;
        amount = referralsInfo[user].accumulatedAmount;
    }

    /**
     * @dev redeem tokens
     * @param userAddr redeemer address
     * @param qualifiedNonce of the user
     * @param tokensPerCredit to redeem
     * @param plasmaRoot to deposit
     */
    function redeemTokens(
        address userAddr,
        uint256 qualifiedNonce,
        uint256 tokensPerCredit,
        address plasmaRoot
    )
        external onlyReferralManager
    {
        ReferralInfo storage referralInfo = referralsInfo[userAddr];

        /// Check nonce
        require(qualifiedNonce > referralInfo.qualifiedNonce, "qualifiedNonce is invalid");

        /// Calculate net amount to send
        uint256 amount = (qualifiedNonce - referralInfo.qualifiedNonce) * tokensPerCredit;

        referralInfo.qualifiedNonce = qualifiedNonce;
        referralInfo.accumulatedAmount = referralInfo.accumulatedAmount.add(amount);

        /// Call plasma deposit
        _plasmaDeposit(userAddr, amount, plasmaRoot);

        emit Redeemed(userAddr, amount);
    }

    /**
     * @dev transfer tokens to multiple addresses
     * @param _destArray Array of destination addresses
     * @param _amountArray Array of amounts to transfer to each corresponding address.
     */
    function bulkTransfer(
        address[] calldata _destArray,
        uint256[] calldata _amountArray
    )
        external whenNotPaused
    {
        require(_destArray.length == _amountArray.length, "arrays should be of same lenght");

        for (uint x = 0; x < _amountArray.length; x++) {
            _transfer(msg.sender, _destArray[x], _amountArray[x]);
        }
    }

    /**
     * Atomically approve and transfer tokens to a plasma sidechain.
     *  only used by admin.
     * @param userTo address to deposit tokens to
     * @param amount of tokens to transfer
     * @param plasmaRoot address of the plasma contract
     */
    function plasmaDeposit(
        address userTo,
        uint256 amount,
        address plasmaRoot
    )
        external onlyReferralManager
    {
        _plasmaDeposit(userTo, amount, plasmaRoot);
    }

    /**
     * Atomically approve and transfer tokens to a plasma sidechain
     * @param amount of tokens to transfer
     * @param plasmaRoot address of the plasma contract
     */
    function plasmaDeposit(uint256 amount, address plasmaRoot) external {
        _plasmaDeposit(msg.sender, amount, plasmaRoot);
    }

    /**
     * @dev Atomically increases the allowance and calls plasma depositERC20ForUser()
     * @param toAddr user address to deposit
     * @param amount amount to deposit
     * @param plasmaRoot address of the plasma calling contract
     */
    function _plasmaDeposit(
        address toAddr,
        uint256 amount,
        address plasmaRoot
    ) private {
        require(amount > 0, "invalid amount");
        require(allowance(address(this), plasmaRoot) == 0, "plasmaRoot allowance is > 0");

        /// Temporary deposit sender's tokens in this contract
        ///  and call Plasma deposit() to transfer them
        _transfer(msg.sender, address(this), amount);
        _approve(address(this), plasmaRoot, amount);

        /// Call plasma deposit
        IPlasmaRoot(plasmaRoot).depositERC20ForUser(
            address(this),
            toAddr,
            amount
        );

        emit PlasmaDeposit(toAddr, amount);
    }
}
