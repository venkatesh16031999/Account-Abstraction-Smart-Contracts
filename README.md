# Account Abstraction and Smart Contract Wallets

This repository contains all the smart contracts that is required for the Account Abstraction (ERC4337) stack and deployment files from setting up the entry point + smart contract wallet contracts to executing user operations.

## Contract Files

What are the different contracts included in this repository
1. Entry Point Core contracts - The main/core contracts for the Account Abstraction feature.
2. Smart Wallet Contract - A smart contract wallet to manage funds, authorize access and execute other transactions.
3. Wallet Proxy Contract - A proxy contract which delegates the calls from proxy to implementation smart contract wallets.
4. Wallet Factory - This contract is primarily used by the entry point contract to deploy a smart wallet for users. Create2 deterministic deployment approach is used here
5. Modules Management Contract - This contract is primailry used as a module registry contract to enable, disable and setup different modules for our smart wallet.
6. ECDSAAuthorization Contract - This is an contract which is used an a Auth module for our smart wallets. This manages the ownership of smart wallets for EOA accounts

These are the primary contract which facilitates the Account Abstraction feature. There are few other utility contracts to help other contracts.

## Deployment Files

The deployment files handle the deployment of the smart wallet contract to the EVM Chain. They include scripts for deploying the contract, verifying the contract on Etherscan, and interacting with the deployed contract.

### Deployment and interaction sequence

1. Deploy the entry point Contract which is an main core contract of Account abstraction
2. Deploy the smart account implementation Contract which is a smart wallet account generated for every EOA account
3. Deploy the ECDSA Authorization module contract which is used for the ownership management of smart account
4. Deploy Smart account wallet factory contract which is used to deploy deterministic smart accounts for EOA's
5. Deploy smart account wallet for an EOA account using Create2 deployment flow
6. During the smart account deployment, an EOA account will be added as owner of the smart accout in ECDSA module
7. Deploy MockERC20 token contract
8. Mint some ERC20 tokens to the smart wallet account and transfer some gas tokens for paying gas fees
9. Create a raw user operation transaction for approving and sending the ERC20 token from smart account to EOA wallet
10. Estimate gas fees for user operation and generate signature for the user operation
11. Execute the user operation by calling the handleOps function from entry point contract.
12. The user operation is a batch execution of approve and transfer, hence these two actions will be performed in a single transaction
13. Check the updated balance of EOA account and Smart account

Please refer to the individual files for more detailed comments on the code.

## Account Abstraction and Entry Point Contract Flow:


![alt Account Abstraction Architecture](https://github.com/venkatesh16031999/Blockchain/blob/erc4337/account-abstraction/EntryPointContract.png)



