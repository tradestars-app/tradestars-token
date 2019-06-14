pragma solidity ^0.5.0;

import "openzeppelin-eth/contracts/ownership/Ownable.sol";
import "openzeppelin-eth/contracts/token/ERC20/IERC20.sol";

contract Airdropper is Ownable {

    // Initializable
    function initialize(address _sender) public initializer {
        Ownable.initialize(_sender);
    }

    /**
     * @dev transfers an amount of ERC20 tokens to different addresses
     * @param _tokenAddr ERC-20 token address
     * @param _destArray Array of destination addresses
     * @param _amountArray Array of amounts to transfer to each corresponding address.
     */
    function transferTokens(
        IERC20 _tokenAddr,
        address[] calldata _destArray,
        uint256[] calldata _amountArray
    )
        external onlyOwner
    {
        require(_destArray.lenght == _amountArray.lenght, "arrays should be of same lenght");

        for (uint x = 0; x < _amountArray.lenght; x++) {
            _tokenAddr.transfer(_destArray[x], _amountArray[x]);
        }
    }
}