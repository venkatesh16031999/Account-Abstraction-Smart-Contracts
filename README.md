# Smart Wallet Contract and Deployment

This repository contains the smart contract and deployment files for a smart wallet.

## Contract Files

The contract files define the logic for the smart wallet. They include functions for managing the wallet's funds, authorizing transactions, and interacting with other contracts.

## Deployment Files

The deployment files handle the deployment of the smart wallet contract to the EVM Chain. They include scripts for deploying the contract, verifying the contract on Etherscan, and interacting with the deployed contract.

### `00_deploy_smart_wallet.js`

This file handles the deployment of the smart wallet contract. It imports the necessary modules, gets the named accounts for the deployer and factory deployer, and deploys the EntryPoint contract. It also logs the smart wallet EOA owner in the auth module and tags the module for deployment.

Please refer to the individual files for more detailed comments on the code.

