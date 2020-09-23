// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;


library SafeDelegate {

    function callfn(
        address _target,
        bytes memory _data,
        string memory _errorMessage
    )
        internal returns (bytes memory)
    {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = _target.delegatecall(_data);
        if (success) {
            return returndata;
        }

        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }

        } else {
            revert(_errorMessage);
        }
    }
}
