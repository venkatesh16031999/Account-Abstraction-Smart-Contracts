// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

// Importing necessary contracts and interfaces
import "./base/ModuleManager.sol";
import "./interfaces/IAccount.sol";
import "./utils/Validation.sol";
import "./interfaces/IEntryPoint.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @title SmartWalletErrors
 * @dev Defines all error messages for the SmartWallet contract
 */
contract SmartWalletErrors {
    error CallerIsNotEntryPoint(address sender);
    error CallerIsNotEntryPointOrSelf(address sender);
    error WrongExecutionBatchInfo(
        uint256 targetsLength,
        uint256 valuesLength,
        uint256 datasLength
    );
    error DelegateCallsOnly();
    error AlreadyInitialized();
}

/**
 * @title SmartWallet
 * @dev A smart contract wallet that supports modules and batch transactions.
 * It is also an entry point for user operations.
 */
contract SmartWallet is Initializable, IAccount, ModuleManager, SmartWalletErrors {
    // Immutable variables for the entry point and self address
    IEntryPoint private immutable entryPoint;
    address public immutable self;

    // Event emitted when the smart account receives native token
    event SmartAccountReceivedNativeToken(address indexed sender, uint256 indexed value);

    /**
     * @dev Constructor for the SmartWallet contract
     * @param _entryPoint The entry point for the smart contract
     */
    constructor(IEntryPoint _entryPoint) {
        // Check if the entry point address is not zero
        Validation.checkForZeroAddress(address(_entryPoint));
        // Assign the entry point and self address
        entryPoint = _entryPoint;
        self = address(this);
    }

    /**
     * @dev Initializes the smart contract
     * @param initializerTarget The target for initialization
     * @param initData The data for initialization
     */
    function init(
        address initializerTarget,
        bytes calldata initData
    ) external initializer returns (address) {
        // Setup and enable the module with the provided initializer target and data
        return _setupAndEnableModule(initializerTarget, initData);
    }

    /**
     * @dev Function to receive Ether
     */
    receive() external payable {
        // Check if the function is called by delegate call
        if (address(this) == self) revert DelegateCallsOnly();
        // Emit event when the smart account receives native token
        emit SmartAccountReceivedNativeToken(msg.sender, msg.value);
    }

    /**
     * @dev Enables a module
     * @param module The module to enable
     */
    function enableModule(
        address module
    ) external override onlyEntryPointOrSelfAuthorized {
        // Enable the provided module
        _enableModule(module);
    }

    /**
     * @dev Disables a module
     * @param prevModule The previous module
     * @param module The module to disable
     */
    function disableModule(
        address prevModule,
        address module
    ) external override onlyEntryPointOrSelfAuthorized {
        // Disable the provided module
        _disableModule(prevModule, module);
    }

    /**
     * @dev Executes a transaction
     * @param target The target of the transaction
     * @param value The value of the transaction
     * @param data The data of the transaction
     */
    function _execute(
        address target,
        uint256 value,
        bytes memory data
    ) internal {
        // Execute the transaction using inline assembly
        assembly {
            let success := call(gas(), target, value, add(data, 0x20), mload(data), 0, 0)
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, returndatasize())
            if iszero(success) {
                revert(ptr, returndatasize())
            }
        }
    }

    /**
     * @dev Executes a transaction
     * @param target The target of the transaction
     * @param value The value of the transaction
     * @param data The data of the transaction
     */
    function execute(
        address target,
        uint256 value,
        bytes calldata data
    ) external onlyEntryPoint {
        // Execute the transaction
        _execute(target, value, data);
    }

    /**
     * @dev Executes a batch of transactions
     * @param targets The targets of the transactions
     * @param values The values of the transactions
     * @param datas The data of the transactions
     */
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external onlyEntryPoint {
        // Check if the lengths of the targets, values, and datas arrays are equal
        if (
            targets.length == 0 ||
            targets.length != values.length ||
            values.length != datas.length
        ) revert WrongExecutionBatchInfo(targets.length, values.length, datas.length);

        // Execute each transaction in the batch
        for (uint256 i; i < targets.length; ) {
            _execute(targets[i], values[i], datas[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Adds a deposit to the smart contract
     */
    function addDeposit() external payable {
        // Deposit the sent value to the entry point
        entryPoint.depositTo{value: msg.value}(address(this));
    }

    /**
     * @dev Gets the deposit of the smart contract
     * @return The deposit of the smart contract
     */
    function getDeposit() external view returns (uint256) {
        // Return the balance of the entry point
        return entryPoint.balanceOf(address(this));
    }

    /**
     * @dev Withdraws a deposit to a specified address
     * @param withdrawAddress The address to withdraw to
     * @param amount The amount to withdraw
     */
    function withdrawDepositTo(
        address payable withdrawAddress,
        uint256 amount
    ) external payable onlyEntryPointOrSelfAuthorized {
        // Withdraw the specified amount to the provided address
        entryPoint.withdrawTo(withdrawAddress, amount);
    }

    /**
     * @dev Validates a user operation
     * @param missingAccountFunds The missing funds from the account
     * @return validationData The validation data
     */
    function validateUserOp(
        UserOperation calldata /*userOp*/,
        bytes32 /*userOpHash*/,
        uint256 missingAccountFunds
    ) external onlyEntryPoint returns (uint256 validationData) {
        // If there are missing account funds, send them to the sender
        if (missingAccountFunds != 0) {
            (bool result,) = payable(msg.sender).call{
                value: missingAccountFunds,
                gas: gasleft()
            }("");

            (result);
        }

        return 0;
    }

    /**
     * @dev Sets up and enables a module
     * @param setupContract The contract to set up
     * @param setupData The data for setup
     * @return The address of the module
     */
    function setupAndEnableModule(
        address setupContract,
        bytes memory setupData
    ) external override onlyEntryPointOrSelfAuthorized returns (address) {
        // Setup and enable the module with the provided setup contract and data
        return _setupAndEnableModule(setupContract, setupData);
    }

    /**
     * @dev Gets the nonce of the smart contract
     * @param _key The key for the nonce
     * @return The nonce of the smart contract
     */
    function nonce(uint192 _key) external view virtual returns (uint256) {
        // Return the nonce of the entry point with the provided key
        return entryPoint.getNonce(address(this), _key);
    }

    /**
     * @dev Gets the entry point of the smart contract
     * @return The entry point of the smart contract
     */
    function getEntryPoint() external view returns(address) {
        // Return the address of the entry point
        return address(entryPoint);
    }

    /**
     * @dev Gets the address of the smart contract
     * @return The address of the smart contract
     */
    function getSelf() external view returns(address) {
        // Return the address of the smart contract
        return self;
    }

    /**
     * @dev Gets the version of the smart contract
     * @return v The version of the smart contract
     */
    function version() external pure returns(string memory v) {
        // Return the version of the smart contract
        v = "1";
    }

    /**
     * @dev Modifier to check if the caller is the entry point
     */
    modifier onlyEntryPoint() {
        // Revert if the caller is not the entry point
        if (msg.sender != address(entryPoint)) {
            revert CallerIsNotEntryPoint(msg.sender);
        }
        _;
    }

    /**
     * @dev Modifier to check if the caller is the entry point or self authorized
     */
    modifier onlyEntryPointOrSelfAuthorized() {
        // Revert if the caller is not the entry point or self authorized
        if (msg.sender != address(this) && msg.sender != address(entryPoint)) {
            revert CallerIsNotEntryPointOrSelf(msg.sender);
        }
        _;
    }
}
