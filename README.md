# Smart Wallet Contract and Deployment

This repository contains the smart contract and deployment files for a smart wallet.

## Contract Files

The contract files define the logic for the smart wallet. They include functions for managing the wallet's funds, authorizing transactions, and interacting with other contracts.

## Deployment Files

The deployment files handle the deployment of the smart wallet contract to the EVM Chain. They include scripts for deploying the contract, verifying the contract on Etherscan, and interacting with the deployed contract.

## Deployment and Interaction sequence

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

### `00_deploy_smart_wallet.js`

This file handles the deployment of the smart wallet contract. It imports the necessary modules, gets the named accounts for the deployer and factory deployer, and deploys the EntryPoint contract. It also logs the smart wallet EOA owner in the auth module and tags the module for deployment.

Please refer to the individual files for more detailed comments on the code.

