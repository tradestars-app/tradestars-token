pragma solidity ^0.5.12;

import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Pausable.sol";

interface IPlasmaRoot {
    function deposit(address tokenAddr, address user, uint256 amount) external;
}

contract TSToken is Ownable, ERC20Detailed, ERC20Pausable {

    using SafeERC20 for IERC20;

    event PlasmaDeposit(address indexed from, uint256 amount);
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
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) external {
        _burn(msg.sender, _value);

        tokensBurned = tokensBurned.add(_value);
    }

    /**
     * @dev Burns a specific amount of tokens from the target address and decrements allowance
     * @param _from address The address which you want to send tokens from
     * @param _value uint256 The amount of token to be burned
     */
    function burnFrom(address _from, uint256 _value) external {
        _burnFrom(_from, _value);

        tokensBurned = tokensBurned.add(_value);
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
        external onlyReferralManager whenNotPaused
    {
        ReferralInfo storage referralInfo = referralsInfo[userAddr];

        /// Check nonce
        require(qualifiedNonce > referralInfo.qualifiedNonce, "qualifiedNonce is invalid");

        /// Calculate net amount to send
        uint256 amount = (qualifiedNonce - referralInfo.qualifiedNonce) * tokensPerCredit;
        require(balanceOf(referralManager) >= amount, "referralAdmin has no balance");

        referralInfo.qualifiedNonce = qualifiedNonce;
        referralInfo.accumulatedAmount = referralInfo.accumulatedAmount.add(amount);

        /// transfer TSX to user account
        IERC20(this).safeTransfer(userAddr, amount);

        /// Call plasma deposit()
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
            IERC20(this).safeTransfer(_destArray[x], _amountArray[x]);
        }
    }

    /**
     * Atomically approve and transfer tokens to a plasma sidechain
     * @param amount of tokens to transfer
     * @param plasmaRoot address of the plasma contract
     */
    function plasmaDeposit(uint256 amount, address plasmaRoot) external whenNotPaused {
        _plasmaDeposit(msg.sender, amount, plasmaRoot);
    }

    /**
     * Initializer function.
     */
    function initialize(address _sender) public initializer {
        Ownable.initialize(_sender);

        ERC20Pausable.initialize(_sender);
        ERC20Detailed.initialize(NAME, SYMBOL, DECIMALS);
    }

    /**
     * @dev Atomically increases the allowance and calls plasma deposit()
     * @param toAddr user address
     * @param amount amount to deposit
     * @param plasmaRoot address of the plasma root contract
     */
    function _plasmaDeposit(address toAddr, uint256 amount, address plasmaRoot) private {

        /// Aprove allowance
        IERC20(this).safeApprove(plasmaRoot, amount);

        /// Call plasma deposit
        IPlasmaRoot(plasmaRoot).deposit(
            address(this),
            toAddr,
            amount
        );

        emit PlasmaDeposit(toAddr, amount);
    }
}