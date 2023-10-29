// Importing required modules
const { network, ethers } = require("hardhat");

// Pseudo code flow description
// 1. Deploy the entry point Contract which is an main core contract of Account abstraction
// 2. Deploy the smart account implementation Contract which is a smart wallet account generated for every EOA account
// 3. Deploy the ECDSA Authorization module contract which is used for the ownership management of smart account
// 4. Deploy Smart account wallet factory contract which is used to deploy deterministic smart accounts for EOA's
// 5. Deploy smart account wallet for an EOA account using Create2 deployment flow
// 6. During the smart account deployment, an EOA account will be added as owner of the smart accout in ECDSA module
// 7. Deploy MockERC20 token contract
// 8. Mint some ERC20 tokens to the smart wallet account and transfer some gas tokens for paying gas fees
// 9. Create a raw user operation transaction for approving and sending the ERC20 token from smart account to EOA wallet
// 10. Estimate gas fees for user operation and generate signature for the user operation
// 11. Execute the user operation by calling the handleOps function from entry point contract.
// 12. The user operation is a batch execution of approve and transfer, hence these two actions will be performed in a single transaction
// 13. Check the updated balance of EOA account and Smart account

// Main deployment function
module.exports = async function main({ getNamedAccounts, deployments }) {
    // If deploying the contract in testnet/mainnet ? Use the respective RPC providers to get the provider instance
    const provider = ethers.provider;

    const getNetworkGasFees = async () => {
        const { gasPrice, maxFeePerGas, maxPriorityFeePerGas } = await provider.getFeeData();
        return { gasPrice, maxFeePerGas, maxPriorityFeePerGas };
    }

    // Destructuring deployments object
    const { deploy, log } = deployments;

    // Getting named accounts
    const { deployer, factoryDeployer } = await getNamedAccounts();
    const deployerSigner = await ethers.getSigner(deployer);

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

    // Getting EntryPoint contract instance
    const entryPoint = await ethers.getContractAt("EntryPoint", EntryPoint.address, deployerSigner);

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
    const ecdsaAuthorization = await ethers.getContractAt("ECDSAAuthorization", ECDSAAuthorization.address, deployerSigner);

    // Encoding function data for init function
    const authModuleCalldata = ecdsaAuthorization.interface.encodeFunctionData("init", [deployer]);

    // Deploying WalletFactory contract
    const WalletFactory = await deploy('WalletFactory', {
        from: factoryDeployer,
        args: [SmartWallet.address],
        autoMine: true,
        log: true,
        waitConfirmations: network.config.chainId === 31337 ? 1 : 6
    });

    // Logging WalletFactory deployment
    log(`WalletFactory (${network.name}) deployed to ${WalletFactory.address}`);

    // Getting WalletFactory contract instance
    const walletFactory = await ethers.getContractAt("WalletFactory", WalletFactory.address, deployerSigner);

    // Deploying smart account
    const walletDeploymentTx = await walletFactory.deploySmartAccount(0, ECDSAAuthorization.address, authModuleCalldata);
    await walletDeploymentTx.wait(1);

    // Computing wallet address
    const computedWalletAddress = await walletFactory.getProxyAddress(0);

    // Logging smart wallet address
    console.log("Smart Wallet Address", computedWalletAddress);

    // Getting smart wallet contract instance
    const smartWalletProxy = await ethers.getContractAt("SmartWallet", computedWalletAddress, deployerSigner);

    // Logging smart wallet version
    console.log("Smart wallet version: ", await smartWalletProxy.version());

    // Logging smart wallet EOA owner in auth module
    console.log("Smart wallet EOA owner in auth module: ", await ecdsaAuthorization.getOwner(computedWalletAddress));

    // Deploying MockERC20 contract
    const MockERC20 = await deploy('MockERC20', {
        from: deployer,
        args: [deployer],
        autoMine: true,
        log: true,
        waitConfirmations: network.config.chainId === 31337 ? 1 : 6
    });

    // Logging MockERC20 deployment
    log(`MockERC20 (${network.name}) deployed to ${MockERC20.address}`);

    // Getting MockERC20 contract instance
    const mockERC20 = await ethers.getContractAt("MockERC20", MockERC20.address, deployerSigner);

    const tokenMintTx = await mockERC20.mint(computedWalletAddress, ethers.parseUnits('100', 'ether'));

    // Waiting for the token mint transaction to be mined
    await tokenMintTx.wait(1);

    // Sending ether to the computed wallet address
    await deployerSigner.sendTransaction({
        to: computedWalletAddress,
        value: ethers.parseUnits("100", "ether"),
    });

    // Logging the balance before user operation execution
    console.log("\n============= BALANCE BEFORE USER OPERATION EXECUTION =============");

    // Logging the ERC20 token balance of the smart account
    console.log(
        "ERC20 token Balance of the smart account: ",
        ethers.formatUnits((await mockERC20.balanceOf(computedWalletAddress)).toString(), "ether")
    );

    // Logging the native token balance of the smart account
    console.log(
        "Native token Balance of the smart account: ",
        ethers.formatUnits((await provider.getBalance(computedWalletAddress)).toString(), "ether")
    );

    // Encoding the approve and transfer function data
    const approveCalldata = mockERC20.interface.encodeFunctionData("approve", [deployer, ethers.parseUnits("10", "ether")]);
    const sendCalldata = mockERC20.interface.encodeFunctionData("transfer", [deployer, ethers.parseUnits("10", "ether")]);

    // Encoding the executeBatch function data
    const userOpCalldata = smartWalletProxy.interface.encodeFunctionData("executeBatch", [[MockERC20.address, MockERC20.address], [0, 0], [approveCalldata, sendCalldata]]);

    // Getting the network gas fees
    const networkFees = await getNetworkGasFees();


   // const gasFeesForUserOp = await smartWalletProxy.executeBatch
    //     .estimateGas([MockERC20.address, MockERC20.address], [0, 0], [approveCalldata, sendCalldata]);

    // Creating the base user operation
    const baseUserOp = {
        sender: computedWalletAddress,
        nonce: await smartWalletProxy.nonce(0),
        initCode: "0x",
        callData: userOpCalldata,
        callGasLimit: 91252n, // calculated using the above gas estimation function. 
        verificationGasLimit: 150000n,
        preVerificationGas: 50000,
        maxFeePerGas: networkFees.maxFeePerGas,
        maxPriorityFeePerGas: networkFees.maxPriorityFeePerGas,
        paymasterAndData: "0x",
        signature: "0x",
    }

    // Getting the user operation hash
    const userOpHash = await entryPoint.getUserOpHash(baseUserOp);

    // Converting the user operation hash to bytes
    const userOpHashBytes = ethers.getBytes(userOpHash);

    // Signing the user operation hash
    const signature = await deployerSigner.signMessage(userOpHashBytes);

    // Adding the signature to the base user operation
    baseUserOp.signature = signature;

    // Executing the user operations
    const entryPointExecuteBatchtx = await entryPoint.handleOps(
        [baseUserOp],
        deployer,
        { gasLimit: 15000000 }
    );

    // Waiting for the transaction to be mined
    await entryPointExecuteBatchtx.wait(1);

    // Logging the balance after user operation execution
    console.log("\n============= BALANCE AFTER USER OPERATION EXECUTION =============");
    console.log(
        "ERC20 token Balance of the smart account: ",
        ethers.formatUnits((await mockERC20.balanceOf(computedWalletAddress)).toString(), "ether")
    );

    console.log(
        "Native token Balance of the smart account: ",
        ethers.formatUnits((await provider.getBalance(computedWalletAddress)).toString(), "ether")
    );
};

// Tagging this module for deployment
module.exports.tags = ["all"];
