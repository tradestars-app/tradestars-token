// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";


contract TSX is Initializable, Ownable, Pausable, ERC20Snapshot {

    /// Token details
    string public constant NAME = "TradeStars TSX";
    string public constant SYMBOL = "TSX";

    constructor() Ownable() ERC20(NAME, SYMBOL) public { }

    /**
     * Initializer function.
     */
    function initialize() public initializer { }

    /**
     * @dev changes the paused state. called by owner only
     * @param _setPaused paused status
     */
    function pause(bool _setPaused) public onlyOwner {
        _setPaused ? _pause() : _unpause();
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
     * @dev Destroys `amount` tokens from the caller.
     */
    function burn(uint256 _amount) public virtual {
        _burn(msg.sender, _amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     */
    function burnFrom(address _account, uint256 _amount) public virtual {
        uint256 decreasedAllowance = allowance(_account, msg.sender).sub(_amount, "ERC20: burn amount exceeds allowance");

        _approve(_account, msg.sender, decreasedAllowance);
        _burn(_account, _amount);
    }

    /**
     * @dev _beforeTokenTransfer hook
     */
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    )
        internal virtual override
    {
        super._beforeTokenTransfer(_from, _to, _amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}
