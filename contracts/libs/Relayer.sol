// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";

abstract contract Relayer {

    using ECDSA for bytes32;

    // Relayed signatures map
    mapping(bytes => bool) private relayedSignatures;

    /**
     * @dev Executes a transaction that was relayed by a 3rd party
     * @param _nonce tx nonce
     * @param _signer signer who's the original beneficiary
     * @param _abiEncoded function signature
     * @param _orderHashSignature keccak256(nonce, signer, function)
     */
    function executeRelayedTx(
        uint256 _nonce,
        address _signer,
        bytes calldata _abiEncoded,
        bytes calldata _orderHashSignature
    )
        external returns (bytes memory)
    {
        require(
            relayedSignatures[_orderHashSignature] == false,
            "Relayer: Invalid _orderSignature"
        );

        // Check hashed message & signature
        bytes32 _hash = keccak256(
            abi.encodePacked(_nonce, _signer, _abiEncoded)
        );

        require(
            _signer == _hash.toEthSignedMessageHash().recover(_orderHashSignature),
            "Relayer: invalid signature verification"
        );

        relayedSignatures[_orderHashSignature] = true;

        // Append signer address at the end to extract it from calling context
        (bool success, bytes memory returndata) = address(this).call(
            abi.encodePacked(_abiEncoded, _signer)
        );

        if (success) {
            return returndata;
        }

        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {

            // solhint-disable-next-line no-inline-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }

        } else {
            revert("Relayer: error in call()");
        }
    }


    /**
     * @dev Returns message sender. If its called from a relayed call it gets
     *  the sender address from last 20 bytes msg.data
     */
    function _getSafeRelayedSender() internal view returns (address payable result) {
        if (msg.sender == address(this)) {

            bytes memory array = msg.data;
            uint256 index = msg.data.length;

            // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
            assembly {
                result := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
            return result;
        }
        return msg.sender;
    }
}
