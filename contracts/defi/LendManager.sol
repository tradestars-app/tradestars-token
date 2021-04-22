// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../defi/ILendManager.sol";

abstract contract LendManager is Ownable, ILendManager {

    using SafeERC20 for IERC20;

    // Mapping based on token <> interest-bearing derivative
    mapping (address => address) private tokensMap;

    function setMappedToken(address _token, address _mappedToken) public override onlyOwner {
        tokensMap[_token] = _mappedToken;
    }

    function getMappedToken(address _token) public view override returns (address) {
        address mappedToken = tokensMap[_token];

        require(
            mappedToken != address(0),
            "LendManager: address not mapped"
        );

        return mappedToken;
    }
}
