// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

// Importing required modules
import "../utils/Validation.sol";
import "../Proxy.sol";
import "../utils/Validation.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "../SmartWallet.sol";

/**
 * @title WalletFactory
 * @dev This contract is used to create new wallet contracts.
 */
contract WalletFactory {
    // Address of the implementation contract
    address public immutable implementation;

    // Event emitted when a new account is created
    event AccountCreated(address indexed proxy, address indexed implementation);

    /**
     * @dev Constructor that sets the implementation address.
     * @param _implementation The address of the implementation contract.
     */
    constructor(address _implementation) {
        Validation.checkForZeroAddress(_implementation);
        implementation = _implementation;
    }

    /**
     * @dev Returns the bytecode of the Proxy contract.
     * @return bytecode The bytecode of the Proxy contract.
     */
    function getBytecode() internal view returns (bytes memory bytecode) {
        bytecode = abi.encodePacked(
            type(Proxy).creationCode,
            uint256(uint160(implementation))
        );
    }

    /**
     * @dev Deploys a new SmartWallet contract.
     * @param _salt The salt used for the Create2 deployment.
     * @param _initialTarget The initial target of the SmartWallet contract.
     * @param _initData The initialization data for the SmartWallet contract.
     * @return walletProxy The address of the newly deployed SmartWallet contract.
     */
    function deploySmartAccount(
        uint256 _salt,
        address _initialTarget,
        bytes calldata _initData
    ) external returns (address walletProxy) {
        bytes32 salt = keccak256(abi.encodePacked(_salt));

        // Deploying the SmartWallet contract
        walletProxy = Create2.deploy(0, salt, getBytecode());

        bytes memory initializer;
        
        // If initial target and initialization data are provided, prepare the initializer
        if (_initialTarget != address(0) && _initData.length > 0) {
            initializer = abi.encodeCall(
                SmartWallet.init,
                (_initialTarget, _initData)
            );
        }

        // If initializer is prepared, execute it
        if (initializer.length > 0) {
               assembly {
                let result := call(
                    gas(),
                    walletProxy,
                    0,
                    add(initializer, 0x20),
                    mload(initializer),
                    0,
                    0
                )
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize())
                if iszero(result) {
                    revert(ptr, returndatasize())
                }
            }
        }

        // Emitting event for account creation
        emit AccountCreated(walletProxy, implementation);
    }

    /**
     * @dev Returns the address of the proxy contract.
     * @param _salt The salt used for the Create2 deployment.
     * @return walletProxy The address of the proxy contract.
     */
    function getProxyAddress(uint256 _salt) external view returns (address walletProxy) {
        bytes32 salt = keccak256(abi.encodePacked(_salt));
        walletProxy = Create2.computeAddress(salt, keccak256(getBytecode()), address(this));
    }
}
