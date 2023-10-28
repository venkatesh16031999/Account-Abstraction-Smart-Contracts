// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * @title Validation
 * @dev This library provides utility functions for validating input data.
 */
library Validation {
    // Error to be thrown when a zero address is encountered
    error ZeroAddressNotAllowed();

    /**
     * @dev Checks if the provided address is a zero address.
     * @param _address The address to be checked.
     * @notice ZeroAddressNotAllowed if the address is a zero address.
     */
	function checkForZeroAddress(address _address) internal pure {
		// If the address is a zero address, revert the transaction
		if (_address == address(0)) {
			revert ZeroAddressNotAllowed();
		}
	}
}