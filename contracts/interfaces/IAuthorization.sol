// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { UserOperation } from "../core/UserOperation.sol";

/**
 * @title IAuthorization
 * @dev This interface is for modules to verify signatures signed over userOpHash
 */
interface IAuthorization {
    /**
     * @notice This function validates the user operation
     * @param userOp The user operation to validate
     * @param userOpHash The hash of the user operation
     * @return validationData The validation data of the user operation
     */
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) external returns (uint256 validationData);
}