// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";


// mock class using ERC21
contract ERC20Mock is ERC20 {
    constructor (string memory _name, string memory _symbol) ERC20(_name, _symbol) public {

    }

    function mint(address _recipient, uint256 _amount) public {
        _mint(_recipient, _amount);
    }
}

contract ERC20MockBurnable is ERC20Mock, ERC20Burnable {
    constructor (string memory _name, string memory _symbol) ERC20Mock(_name, _symbol) public {

    }
}
