// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/**
 * @dev {TSX}:
 *  - mint/burn/pause capabilities
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */

contract TSX is AccessControlEnumerable, ERC20Snapshot, ERC20Burnable, ERC20Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // Token details
    string public constant NAME = "TradeStars TSX";
    string public constant SYMBOL = "TSX";

    constructor() ERC20(NAME, SYMBOL) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
    }

    /**
     * @dev Mints a specific amount of tokens. The caller must have the `MINTER_ROLE`.
     * @param _to The amount of token to be minted.
     * @param _value The amount of token to be minted.
     */
    function mint(address _to, uint256 _value) public virtual {
        require(hasRole(MINTER_ROLE, msg.sender), "TSX: must have minter role to mint");
        _mint(_to, _value);
    }

    /**
     * @dev Pauses all token transfers. The caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, msg.sender), "TSX: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers. the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, msg.sender), "TSX: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from, 
        address to, 
        uint256 amount
    ) 
        internal virtual override(ERC20, ERC20Snapshot, ERC20Pausable) 
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
