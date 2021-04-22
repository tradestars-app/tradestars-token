// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { TransferWithSigERC20 } from "../eip712/TransferWithSigERC20.sol";


contract sTSX is Ownable, TransferWithSigERC20 {

    // Token details
    string public constant NAME = "TradeStars sTSX";
    string public constant SYMBOL = "sTSX";

    // allowed address to manage the supply for this token
    address public minter;

    modifier onlyMinter() {
        require(msg.sender == minter, "sTSX: caller is not minter");
        _;
    }

    constructor() Ownable() ERC20(NAME, SYMBOL) public { }

    /**
     * @dev Sets the minter role for this contract
     * @param _minter address
     */
    function setMinterAddress(address _minter) public onlyOwner {
        minter = _minter;
    }

    /**
     * @dev Sets approval amount for an operator to spend on token owner's behalf
     * @param _owner of the tokens
     * @param _operator spender address
     * @param _amount max amount of tokens allowed to spend
     */
    function approveOperator(
        address _owner,
        address _operator,
        uint256 _amount
    )
        public onlyOwner
    {
        _approve(_owner, _operator, _amount);
    }

    /**
     * @dev Mints a specific amount of tokens.
     * @param _to address to send new tokens to.
     * @param _amount of token to be minted.
     */
    function mint(address _to, uint256 _amount) external onlyMinter {
        _mint(_to, _amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     * @param _amount of token to be burned.
     */
    function burn(uint256 _amount) external onlyMinter {
        _burn(msg.sender, _amount);
    }
}
