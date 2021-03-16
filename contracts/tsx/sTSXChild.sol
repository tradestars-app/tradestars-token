// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { Relayer } from "../libs/Relayer.sol";
import { IChildToken } from "../matic/IChildToken.sol";
import { TransferWithSigERC20 } from "../eip712/TransferWithSigERC20.sol";


contract sTSXChild is Ownable, TransferWithSigERC20, IChildToken, Relayer {

    /// Token details
    string public constant NAME = "TradeStars sTSX";
    string public constant SYMBOL = "sTSX";

    // Allowed deposit
    address private depositorRole;

    constructor() Ownable() ERC20(NAME, SYMBOL) public {

    }

    /**
     * @dev changes the depositor address. called by owner only
     * @param _depositorAddress allowed depositor
     */
    function setDepositor(address _depositorAddress) public onlyOwner {
        depositorRole = _depositorAddress;
    }

    /**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by depositorRole
     *  Should handle deposit by minting the required amount for user
     * @param user user address for whom deposit is being done
     * @param depositData abi encoded amount
     */
    function deposit(address user, bytes calldata depositData) external override {
        require(
            msg.sender == depositorRole,
            "deposit: caller not allowed"
        );

        uint256 amount = abi.decode(depositData, (uint256));

        _mint(user, amount);
    }

    /**
     * @notice called when user wants to withdraw tokens back to root chain.
     *  Can be called relayed
     * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
     * @param amount amount of tokens to withdraw
     */
    function withdraw(uint256 amount) external override {
        // get msg.sender
        address burner = _getSafeRelayedSender();

        _burn(burner, amount);
    }
}
