// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {SelfAuthorized} from "../utils/SelfAuthorized.sol";
import "../utils/Exec.sol";

/**
 * @title Module Manager - A contract that manages modules that can execute transactions
 *        on behalf of the Smart Account via this contract.
 * @dev This contract is responsible for managing modules that can execute transactions
 *      on behalf of the Smart Account. It provides functionality to add, remove, and
 *      execute transactions from modules.
 */
contract ModuleManagerErrors {
    // Custom errors
    error ModulesAlreadyInitialized();
    error ModulesSetupExecutionFailed();
    error ModuleCannotBeZeroOrSentinel(address module);
    error ModuleAlreadyEnabled(address module);
    error ModuleAndPrevModuleMismatch(
        address expectedModule,
        address returnedModule,
        address prevModule
    );
    error ModuleNotEnabled(address module);
    error WrongBatchProvided(
        uint256 destLength,
        uint256 valueLength,
        uint256 funcLength,
        uint256 operationLength
    );
    error WrongModuleSetupAddress(address target);
}

/**
 * @title Module Manager
 * @dev This contract is responsible for managing modules that can execute transactions
 *      on behalf of the Smart Account. It provides functionality to add, remove, and
 *      execute transactions from modules.
 */
abstract contract ModuleManager is SelfAuthorized, ModuleManagerErrors {
    // This can be represented as Default module | No Module | Sentinal Module 
    address internal constant SENTINEL_MODULES = address(0x1);

    // Tracks the list of enabled modules 
    mapping(address => address) internal _modules;

    // Based on the needs, the module can perform call vs delegatecall
    enum Operation {
        DelegateCall,
        Call
    }

    // Events
    event ExecutionFailure(
        address indexed to,
        uint256 indexed value,
        bytes indexed data,
        Operation operation,
        uint256 txGas
    );
    event ExecutionSuccess(
        address indexed to,
        uint256 indexed value,
        bytes indexed data,
        Operation operation,
        uint256 txGas
    );
    event ModuleEnabled(address module);
    event ModuleDisabled(address module);
    event ModuleExecutionSuccess(address indexed module);
    event ModuleExecutionFailure(address indexed module);
    event ModuleTransaction(
        address module,
        address to,
        uint256 value,
        bytes data,
        Operation operation
    );

    /**
     * @dev Adds a module to the allowlist.
     * @notice This SHOULD only be done via userOp or a selfcall.
     * @param module The address of the module to be added.
     */
    function enableModule(address module) external virtual;

    /**
     * @dev Removes a module from the allowlist.
     * @notice This SHOULD only be done via userOp or a selfcall.
     * @param prevModule The address of the module that points to the module to be removed in the linked list.
     * @param module The address of the module to be removed.
     */
    function disableModule(address prevModule, address module) external virtual;

    /**
     * @dev Setups module for this Smart Account and enables it.
     * @notice This SHOULD only be done via userOp or a selfcall.
     * @param setupContract The address of the contract to setup the module.
     * @param setupData The data to be used for setting up the module.
     * @return The address of the setup module.
     */
    function setupAndEnableModule(
        address setupContract,
        bytes memory setupData
    ) external virtual returns (address);

    /**
     * @dev Returns array of modules. Useful for a widget
     * @param start Start of the page.
     * @param pageSize Maximum number of modules that should be returned.
     * @return array Array of modules.
     * @return next Start of the next page.
     */
    function getModulesPaginated(
        address start,
        uint256 pageSize
    ) external view returns (address[] memory array, address next) {
        array = new address[](pageSize);

        uint256 moduleCount;
        address currentModule = _modules[start];
        while (
            currentModule != address(0x0) &&
            currentModule != SENTINEL_MODULES &&
            moduleCount < pageSize
        ) {
            array[moduleCount] = currentModule;
            currentModule = _modules[currentModule];
            moduleCount++;
        }
        next = currentModule;

        assembly {
            mstore(array, moduleCount)
        }
    }

    /**
     * @dev Execute the module transaction
     * @param to Target address
     * @param value Number of native gas to be transferred along with
     * @param data Operation calldata
     * @param operation Type of operation (call vs delegate call)
     * @param txGas remaining gas to be transferred
     * @return result execution result
     */
    function _execute(
        address to,
        uint256 value,
        bytes memory data,
        Operation operation,
        uint256 txGas
    ) internal returns (bool result) {
        if (operation == Operation.Call) {
            result = Exec.call(to, value, data, txGas);
        } else {
            result = Exec.delegateCall(to, data, txGas);
        }

        if (result) {
            emit ExecutionSuccess(to, value, data, operation, txGas);
        } else {
            emit ExecutionFailure(to, value, data, operation, txGas);
        }
    }

    /**
     * @dev Allows a Module to execute a Smart Account transaction without any further confirmations.
     * @param to Destination address of module transaction.
     * @param value Ether value of module transaction.
     * @param data Data payload of module transaction.
     * @param operation Operation type of module transaction.
     * @param txGas remaining gas to be transferred
     * @return success True if the transaction was successful, false otherwise.
     */
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Operation operation,
        uint256 txGas
    ) public virtual returns (bool success) {
        if (
            msg.sender == SENTINEL_MODULES || _modules[msg.sender] == address(0)
        ) revert ModuleNotEnabled(msg.sender);

        success = _execute(
            to,
            value,
            data,
            operation,
            txGas == 0 ? gasleft() : txGas
        );
    }

    /**
     * @dev Allows a Module to execute a Smart Account transaction without any further confirmations.
     * @param to Destination address of module transaction.
     * @param value Ether value of module transaction.
     * @param data Data payload of module transaction.
     * @param operation Operation type of module transaction.
     * @return success True if the transaction was successful, false otherwise.
     * @return returnData The data returned by the transaction.
     */
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Operation operation
    ) public returns (bool success, bytes memory returnData) {
        success = execTransactionFromModule(to, value, data, operation, 0);
        returnData = Exec.getReturnData(0);
    }

    /**
     * @dev Allows a Module to execute a batch of Smart Account transactions without any further confirmations.
     * @param to Destination address of module transaction.
     * @param value Ether value of module transaction.
     * @param data Data payload of module transaction.
     * @param operations Operation type of module transaction.
     * @return success True if all transactions were successful, false otherwise.
     */
    function execBatchTransactionFromModule(
        address[] calldata to,
        uint256[] calldata value,
        bytes[] calldata data,
        Operation[] calldata operations
    ) public virtual returns (bool success) {
        if (
            to.length == 0 ||
            to.length != value.length ||
            value.length != data.length ||
            data.length != operations.length
        )
            revert WrongBatchProvided(
                to.length,
                value.length,
                data.length,
                operations.length
            );

        if (
            msg.sender == SENTINEL_MODULES || _modules[msg.sender] == address(0)
        ) revert ModuleNotEnabled(msg.sender);

        for (uint256 i; i < to.length; ) {
            success = _executeFromModule(
                to[i],
                value[i],
                data[i],
                operations[i]
            );
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Returns if a module is enabled
     * @param module The address of the module to check.
     * @return True if the module is enabled, false otherwise.
     */
    function isModuleEnabled(address module) public view returns (bool) {
        return SENTINEL_MODULES != module && _modules[module] != address(0);
    }

    /**
     * @dev Adds a module to the allowlist.
     * @notice This can only be done via a userOp or a selfcall.
     * @notice Enables the module `module` for the wallet.
     * @param module Module to be allow-listed.
     */
    function _enableModule(address module) internal virtual {
        if (module == address(0) || module == SENTINEL_MODULES)
            revert ModuleCannotBeZeroOrSentinel(module);
        if (_modules[module] != address(0)) revert ModuleAlreadyEnabled(module);

        _modules[module] = _modules[SENTINEL_MODULES];
        _modules[SENTINEL_MODULES] = module;

        emit ModuleEnabled(module);
    }

    /**
     * @dev Setups module for this Smart Account and enables it.
     * @notice This can only be done via userOp or a selfcall.
     * @param setupContract The address of the contract to setup the module.
     * @param setupData The data to be used for setting up the module.
     * @return The address of the setup module.
     */
    function _setupAndEnableModule(
        address setupContract,
        bytes memory setupData
    ) internal virtual returns (address) {
        address module = _setupModule(setupContract, setupData);
        _enableModule(module);
        return module;
    }

    /**
     * @dev Removes a module from the allowlist.
     * @notice This can only be done via a wallet transaction.
     * @notice Disables the module `module` for the wallet.
     * @param prevModule Module that pointed to the module to be removed in the linked list
     * @param module Module to be removed.
     */
    function _disableModule(
        address prevModule,
        address module
    ) internal virtual {
        // Validate module address and check that it corresponds to module index.
        if (module == address(0) || module == SENTINEL_MODULES)
            revert ModuleCannotBeZeroOrSentinel(module);
        if (_modules[prevModule] != module)
            revert ModuleAndPrevModuleMismatch(
                module,
                _modules[prevModule],
                prevModule
            );
        _modules[prevModule] = _modules[module];
        delete _modules[module];
        emit ModuleDisabled(module);
    }

    /**
     * @dev Executes a transaction from a module.
     * @param to The address to execute the transaction on.
     * @param value The amount of Ether to send with the transaction.
     * @param data The data to send with the transaction.
     * @param operation The type of operation to perform.
     * @return success True if the transaction was successful, false otherwise.
     */
    function _executeFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Operation operation
    ) internal returns (bool success) {
        success = _execute(to, value, data, operation, gasleft());

        if (success) {
            emit ModuleTransaction(msg.sender, to, value, data, operation);
            emit ModuleExecutionSuccess(msg.sender);
        } else emit ModuleExecutionFailure(msg.sender);
    }

    /**
     * @dev Setups a module.
     * @param setupContract The address of the contract to setup the module.
     * @param setupData The data to be used for setting up the module.
     * @return module The address of the setup module.
     */
    function _setupModule(
        address setupContract,
        bytes memory setupData
    ) internal returns (address module) {
        if (setupContract == address(0))
            revert WrongModuleSetupAddress(setupContract);
        bool success = Exec.call(setupContract, 0, setupData, gasleft());
        bytes memory returnData = Exec.getReturnData(0);

        if (success) {
            module = address(uint160(bytes20(returnData)));
        } else {
            Exec.revertWithData(returnData);
        }
    }
}
