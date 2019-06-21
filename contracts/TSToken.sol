pragma solidity ^0.5.0;

import "openzeppelin-eth/contracts/ownership/Ownable.sol";
import "openzeppelin-eth/contracts/token/ERC20/ERC20Detailed.sol";
import "openzeppelin-eth/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-eth/contracts/token/ERC20/ERC20Pausable.sol";

contract TSToken is Ownable, ERC20Detailed, ERC20Burnable, ERC20Pausable {

    string public constant NAME = "TradeStars TS Utility Coin";
    string public constant SYMBOL = "TS";
    uint8 public constant DECIMALS = 18;

    function initialize(address _sender) public initializer {
        Ownable.initialize(_sender);

        ERC20Pausable.initialize(_sender);
        ERC20Detailed.initialize(NAME, SYMBOL, DECIMALS);
    }

    function mint(address to, uint256 value) public onlyOwner {
        _mint(to, value);
    }
}