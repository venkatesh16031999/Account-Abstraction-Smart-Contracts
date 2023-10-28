// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

// solhint-disable no-inline-assembly

/**
 * @title Exec
 * @dev This library provides utility functions for making different types of contract calls in Solidity.
 * It includes functions for making regular calls, static calls, and delegate calls.
 * It also includes functions for handling the returned data from these calls.
 */
library Exec {
    /**
     * @notice Makes a call to a contract.
     * @dev This function uses inline assembly to make the call.
     * @param to The address of the contract to call.
     * @param value The amount of wei to send with the call.
     * @param data The data to send with the call.
     * @param txGas The amount of gas to use for the call.
     * @return success True if the call was successful, false otherwise.
     */
    function call(
        address to,
        uint256 value,
        bytes memory data,
        uint256 txGas
    ) internal returns (bool success) {
        // Inline assembly is used to make the call.
        assembly {
            success := call(
                txGas,
                to,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
        }
    }

    /**
     * @notice Makes a static call to a contract.
     * @dev This function uses inline assembly to make the static call.
     * @param to The address of the contract to call.
     * @param data The data to send with the call.
     * @param txGas The amount of gas to use for the call.
     * @return success True if the call was successful, false otherwise.
     */
    function staticcall(
        address to,
        bytes memory data,
        uint256 txGas
    ) internal view returns (bool success) {
        // Inline assembly is used to make the static call.
        assembly {
            success := staticcall(txGas, to, add(data, 0x20), mload(data), 0, 0)
        }
    }

    /**
     * @notice Makes a delegate call to a contract.
     * @dev This function uses inline assembly to make the delegate call.
     * @param to The address of the contract to call.
     * @param data The data to send with the call.
     * @param txGas The amount of gas to use for the call.
     * @return success True if the call was successful, false otherwise.
     */
    function delegateCall(
        address to,
        bytes memory data,
        uint256 txGas
    ) internal returns (bool success) {
        // Inline assembly is used to make the delegate call.
        assembly {
            success := delegatecall(
                txGas,
                to,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
        }
    }

    /**
     * @notice Gets the returned data from the last call or delegate call.
     * @dev This function uses inline assembly to get the returned data.
     * @param maxLen The maximum length of the returned data.
     * @return returnData The returned data.
     */
    function getReturnData(
        uint256 maxLen
    ) internal pure returns (bytes memory returnData) {
        // Inline assembly is used to get the returned data.
        assembly {
            let len := returndatasize()
            if and(not(iszero(maxLen)), gt(len, maxLen)) {
                len := maxLen
            }
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, add(len, 0x20)))
            mstore(ptr, len)
            returndatacopy(add(ptr, 0x20), 0, len)
            returnData := ptr
        }
    }

    /**
     * @notice Reverts the transaction with the provided data.
     * @dev This function uses inline assembly to revert the transaction.
     * @param returnData The data to revert with.
     */
    function revertWithData(bytes memory returnData) internal pure {
        // Inline assembly is used to revert the transaction.
        assembly {
            revert(add(returnData, 32), mload(returnData))
        }
    }

    /**
     * @notice Makes a call to a contract and reverts if the call is not successful.
     * @dev This function uses the call function to make the call and the revertWithData function to revert if the call is not successful.
     * @param to The address of the contract to call.
     * @param data The data to send with the call.
     * @param maxLen The maximum length of the returned data.
     */
    function callAndRevert(
        address to,
        bytes memory data,
        uint256 maxLen
    ) internal {
        bool success = call(to, 0, data, gasleft());
        // If the call was not successful, revert the transaction with the returned data.
        if (!success) {
            revertWithData(getReturnData(maxLen));
        }
    }
}
