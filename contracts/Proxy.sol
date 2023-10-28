// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

// Importing validation utilities
import "./utils/Validation.sol";

/**
 * @title Proxy
 * @dev This contract implements a proxy pattern by delegating calls to an implementation contract.
 * The implementation address is stored in the contract storage at the address().
 */
contract Proxy {
    /**
     * @dev Constructor that sets the address of the implementation contract.
     * @param _implementation The address of the implementation contract.
     */
    constructor(address _implementation) {
        // Check if the implementation address is not zero
        Validation.checkForZeroAddress(_implementation);
        // Store the implementation address in the contract storage at the address()
        assembly {
            sstore(address(), _implementation)
        }
    }

    /**
     * @dev Fallback function that delegates calls to the implementation contract.
     * If the call fails, it reverts with the revert reason from the called contract.
     */
    fallback() external payable {
        assembly {
            // Load the address of the implementation contract
            let target := sload(address())
            // Copy calldata to memory
            calldatacopy(0, 0, calldatasize())
            // Delegate call to the implementation contract
            let result := delegatecall(gas(), target, 0, calldatasize(), 0, 0)
            // Copy returndata to memory
            returndatacopy(0, 0, returndatasize())

            // Check if the call was successful
            switch result 
            case 0 {
                // If the call was not successful, revert with the revert reason from the called contract
                revert(0, returndatasize())
            }
            default {
                // If the call was successful, return with the return data from the called contract
                return(0, returndatasize())
            }
        }
    }
}