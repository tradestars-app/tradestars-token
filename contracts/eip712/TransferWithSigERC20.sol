// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";

import { ITransferWithSig } from "../eip712/ITransferWithSig.sol";
import { LibTokenTransferOrder } from  "../eip712/LibTokenTransferOrder.sol";


abstract contract TransferWithSigERC20 is ITransferWithSig, ERC20, LibTokenTransferOrder {

    using ECDSA for bytes32;

    // transfer() signatures
    mapping(bytes32 => bool) public disabledTransferHashes;

    /**
     * @dev transfers with owmer's signature
     * @param sig caller's signature
     * @param amount amount of tokens to transfer
     * @param data keccak256(abi.encodePacked(_orderId, address(reserveToken), _reserveAmount));
     * @param expiration order
     * @param to beneficiary
     */
    function transferWithSig(
        bytes calldata sig,
        uint256 amount,
        bytes32 data,
        uint256 expiration,
        address to
    ) external override returns (address from) {
        require(amount > 0, "transferWithSig: error in amount");
        require(
            expiration == 0 || block.number <= expiration,
            "transferWithSig: signature is expired"
        );

        bytes32 dataHash = getTokenTransferOrderHash(
            msg.sender,
            amount,
            data,
            expiration
        );

        // mark used signature
        require(
            disabledTransferHashes[dataHash] == false,
            "transferWithSig: sig deactivated"
        );
        disabledTransferHashes[dataHash] = true;

        from = dataHash.recover(sig);

        // call transfer without approval clearance
        _transfer(from, to, amount);
    }
}
