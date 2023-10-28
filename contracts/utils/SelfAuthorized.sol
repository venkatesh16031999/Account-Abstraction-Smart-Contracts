// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * @title SelfAuthorized
 * @dev This contract provides a modifier for functions that should only be called by the contract itself.
 */
contract SelfAuthorized {
    // Error to be thrown when the caller is not the contract itself
    error CallerIsNotSelf(address);

    /**
     * @dev Modifier that requires the caller to be the contract itself.
     */
    modifier authorized() {
        _requireSelfCall();
        _;
    }

    /**
     * @dev Checks if the caller is the contract itself.
     * @notice CallerIsNotSelf if the caller is not the contract itself.
     */
    function _requireSelfCall() private view {
        if (msg.sender != address(this)) revert CallerIsNotSelf(msg.sender);
    }
}