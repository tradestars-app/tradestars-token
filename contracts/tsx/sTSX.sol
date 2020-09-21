// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract sTSX is Initializable, Ownable, ERC20 {

    /// Token details
    string public constant NAME = "TradeStars sTSX";
    string public constant SYMBOL = "sTSX";

    constructor() Ownable() ERC20(NAME, SYMBOL) public { }

    /**
     * Initializer function.
     */
    function initialize() public initializer { }

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
}
