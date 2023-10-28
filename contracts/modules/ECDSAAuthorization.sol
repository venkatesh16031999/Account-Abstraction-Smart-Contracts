// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

// Importing required modules
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../utils/Validation.sol";
import "../interfaces/IAuthorization.sol";

/**
 * @title AuthorizationErrors
 * @dev This contract is used to define all the errors related to Authorization.
 */
contract AuthorizationErrors {
    error NotEOA(address _address);
    error NoRegisteredOwnerForSmartAccount(address smartAccount);
    error InvalidSignature(bytes signature);
    error OwnerAlreadyInitializedForSmartAccount(address smartAccount);
}

/**
 * @title ECDSAAuthorization
 * @dev This contract is used to manage the authorization of smart accounts using ECDSA.
 */
contract ECDSAAuthorization is
    IAuthorization,
    AuthorizationErrors
{
    // Using ECDSA for bytes32
    using ECDSA for bytes32;

    // Mapping of smart account owners
    mapping(address => address) public smartAccountOwners;

    // Event emitted when ownership is transferred
    event OwnershipTransferred(
        address indexed smartAccount,
        address indexed oldOwner,
        address indexed newOwner
    );

    // Function to initialize a smart account with an EOA owner
    function init(address eoaOwner) external returns (address) {
        Validation.checkForZeroAddress(eoaOwner);
        if (smartAccountOwners[msg.sender] != address(0)) revert OwnerAlreadyInitializedForSmartAccount(msg.sender);
        if (_isContract(eoaOwner)) revert NotEOA(eoaOwner);

        smartAccountOwners[msg.sender] = eoaOwner;
        return address(this);
    }

    // Function to transfer ownership of a smart account to a new EOA owner
    function transferOwnership(address eoaOwner) external {
        Validation.checkForZeroAddress(eoaOwner);
        if (_isContract(eoaOwner)) revert NotEOA(eoaOwner);
        _transferOwnership(msg.sender, eoaOwner);
    }

    // Function to renounce ownership of a smart account
    function renounceOwnership() external {
        _transferOwnership(msg.sender, address(0));
    }

    // Internal function to handle ownership transfer
    function _transferOwnership(
        address smartAccount,
        address newOwner
    ) internal {
        address oldOwner = smartAccountOwners[smartAccount];
        smartAccountOwners[smartAccount] = newOwner;
        emit OwnershipTransferred(smartAccount, oldOwner, newOwner);
    }

    // Function to get the owner of a smart account
    function getOwner(address smartAccount) external view returns (address) {
        address owner = smartAccountOwners[smartAccount];
        if (owner == address(0))
            revert NoRegisteredOwnerForSmartAccount(smartAccount);
        return owner;
    }

    // Function to validate user operation
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) external view virtual returns (uint256 validationData) {
        (bytes memory signedSignature, ) = abi.decode(
            userOp.signature,
            (bytes, address)
        );

        if (_verifySignature(userOpHash, signedSignature, userOp.sender)) {
            return 0;
        }

        return 1;
    }

    // Function to check if a signature is valid
    function isValidSignature(
        bytes32 userOpHash,
        bytes memory signature
    ) public view virtual returns (bytes4) {
        if (_verifySignature(userOpHash, signature, msg.sender)) {
            // EIP1271_MAGIC_VALUE
            // bytes4(keccak256("isValidSignature(bytes32,bytes)")
            return 0x1626ba7e;
        }
        return bytes4(0xffffffff);
    }

    // Internal function to verify a signature
    function _verifySignature(
        bytes32 userOpHash,
        bytes memory signature,
        address smartAccount
    ) internal view returns (bool) {
        Validation.checkForZeroAddress(smartAccount);
        address eoaOwner = smartAccountOwners[smartAccount];
        if (eoaOwner == address(0)) revert NoRegisteredOwnerForSmartAccount(smartAccount);
        if (signature.length < 65) revert InvalidSignature(signature);

        // Checking if the recovered address from the signature matches the owner
        if (
            (userOpHash.toEthSignedMessageHash()).recover(signature) == eoaOwner
        ) {
            return true;
        }

        if (userOpHash.recover(signature) == eoaOwner) {
            return true;
        }

        return false;
    }

    // Function to check if an address is a contract
    function _isContract(address _address) internal view returns (bool) {
        uint256 size;

        // Assembly code to check the size of the code at an address
        assembly {
            size := extcodesize(_address)
        }

        return size > 0;
    }
}
