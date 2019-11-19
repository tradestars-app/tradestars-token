pragma solidity ^0.5.12;

import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Pausable.sol";

contract TSToken is Ownable, ERC20Detailed, ERC20Pausable {

    event DepositManagerChange(address depositManager);

    string public constant NAME = "TradeStars TS Utility Coin";
    string public constant SYMBOL = "TS";
    uint8 public constant DECIMALS = 18;

    /// We keep this allowed address for airdrops and deposits
    address private depositManager;
    uint256 public tokensBurned;

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
     * @dev Sets the referral contract address. Can only be called by admin
     * @param _depositManager address
     */
    function setDepositManagerAddress(address _depositManager) external onlyOwner {
        depositManager = _depositManager;
        emit DepositManagerChange(depositManager);
    }

    /**
     * @dev Atomically increases the allowance granted to `plasmaContract` by the owner.
     *  can only be called by the referral contract setted by the admin.
     * @param owner address of the tokens
     * @param addedValue amount to temporary allow plasmaContract to transfer
     * @param plasmaContract address that will take the tokens deposited
     */
    function increaseAllowanceForDeposit(
        address owner,
        uint256 addedValue,
        address plasmaContract
    )
        external whenNotPaused
    {
        uint256 allowance = allowance(owner, plasmaContract);

        /// Check msg sender is our contract && allowance is 0
        require(msg.sender == address(depositManager), "invalid from");
        require(allowance == 0, "plasmaContract as allowance > 0");

        _approve(owner, plasmaContract, allowance.add(addedValue));
    }

    /**
     * Initializer function.
     */
    function initialize(address _owner) public initializer {
        Ownable.initialize(_owner);

        ERC20Pausable.initialize(_owner);
        ERC20Detailed.initialize(NAME, SYMBOL, DECIMALS);
    }
}