// Importing required modules
const { isAddress } = require("ethers");
const { network, ethers } = require("hardhat");
const fs = require("fs").promises;

// Main deployment function
module.exports = async function main({ getNamedAccounts, deployments }) {
    // Destructuring deployments object
    const { deploy, log } = deployments;

    // Getting named accounts
    const { deployer, factoryDeployer } = await getNamedAccounts();

    // Deploying EntryPoint contract
    const EntryPoint = await deploy('EntryPoint', {
        from: deployer,
        args: [],
        autoMine: true,
        log: true,
        waitConfirmations: network.config.chainId === 31337 ? 1 : 6
    });

    // Logging EntryPoint deployment
    log(`EntryPoint (${network.name}) deployed to ${EntryPoint.address}`);

    // Deploying SmartWallet contract
    const SmartWallet = await deploy('SmartWallet', {
        from: deployer,
        args: [EntryPoint.address],
        autoMine: true,
        log: true,
        waitConfirmations: network.config.chainId === 31337 ? 1 : 6
    });

    // Logging SmartWallet deployment
    log(`SmartWallet (${network.name}) deployed to ${SmartWallet.address}`);
    
    // Deploying ECDSAAuthorization contract
    const ECDSAAuthorization = await deploy('ECDSAAuthorization', {
        from: deployer,
        args: [],
        autoMine: true,
        log: true,
        waitConfirmations: network.config.chainId === 31337 ? 1 : 6
    });

    // Logging ECDSAAuthorization deployment
    log(`ECDSAAuthorization (${network.name}) deployed to ${ECDSAAuthorization.address}`);

    // Getting ECDSAAuthorization contract instance
    const ecdsaAuthorization = await ethers.getContractAt("ECDSAAuthorization", ECDSAAuthorization.address, await ethers.getSigner(deployer));

    // Encoding function data for init function
    const authModuleCalldata = ecdsaAuthorization.interface.encodeFunctionData("init", [deployer]);

    // Deploying WalletFactory contract
    const WalletFactory = await deploy('WalletFactory', {
        from: deployer,
        args: [SmartWallet.address],
        autoMine: true,
        log: true,
        waitConfirmations: network.config.chainId === 31337 ? 1 : 6
    });

    // Logging WalletFactory deployment
    log(`WalletFactory (${network.name}) deployed to ${WalletFactory.address}`);

    // Getting WalletFactory contract instance
    const walletFactory = await ethers.getContractAt("WalletFactory", WalletFactory.address, await ethers.getSigner(deployer));

    // Deploying smart account
    const tx = await walletFactory.deploySmartAccount(0, ECDSAAuthorization.address, authModuleCalldata);
    await tx.wait(1);

    // Computing wallet address
    const computedWalletAddress = await await walletFactory.getProxyAddress(0);

    // Logging smart wallet address
    console.log("Smart Wallet Address", computedWalletAddress);

    // Getting smart wallet contract instance
    const smartWalletProxy = await ethers.getContractAt("SmartWallet", computedWalletAddress, await ethers.getSigner(deployer));

    // Logging smart wallet version
    console.log("Smart wallet version: ", await smartWalletProxy.version());

    // Logging smart wallet EOA owner in auth module
    console.log("Smart wallet EOA owner in auth module: ", await ecdsaAuthorization.getOwner(computedWalletAddress));

    // Verification code for non-local network
    // if (network.config.chainId !== 31337) {
    //     await hre.run("verify:verify", {
    //         address: TokenFactory.address,
    //         constructorArguments: args,
    //     });
    // }
};

// Tagging this module for deployment
module.exports.tags = ["all"];
