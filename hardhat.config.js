require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
require("@openzeppelin/hardhat-upgrades");
require("hardhat-deploy");
require("hardhat-contract-sizer");
require("@nomiclabs/hardhat-solhint");
require("@nomicfoundation/hardhat-chai-matchers");

const COMPILER_SETTINGS = {
    optimizer: {
        enabled: true,
        runs: 200,
    }
}

const PRIVATE_KEY = process.env.PRIVATE_KEY;
const FACTORY_DEPLOYER_PRIVATE_KEY = process.env.FACTORY_DEPLOYER_PRIVATE_KEY;

const FORKING_BLOCK_NUMBER = parseInt(process.env.FORKING_BLOCK_NUMBER) || 0;
const REPORT_GAS = process.env.REPORT_GAS || false;

const MUMBAI_RPC_URL = process.env.MUMBAI_RPC_URL;
const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL;

const MUMBAI_DEPLOYMENT_SETTINGS = {
    url: MUMBAI_RPC_URL,
    accounts: PRIVATE_KEY ? [PRIVATE_KEY, FACTORY_DEPLOYER_PRIVATE_KEY] : [],
    chainId: 80001,
}

const SEPOLIA_DEPLOYMENT_SETTINGS = {
    url: SEPOLIA_RPC_URL,
    accounts: PRIVATE_KEY ? [PRIVATE_KEY, FACTORY_DEPLOYER_PRIVATE_KEY] : [],
    chainId: 11155111,
}

const POLYGONSCAN_API_KEY = process.env.POLYGONSCAN_API_KEY;
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;

module.exports = {
    solidity: {
        compilers: [
            {
                version: "0.8.18",
                settings: COMPILER_SETTINGS,
            },
        ],
    },
    networks: {
        hardhat: {
            chainId: 31337,
            // uncomment when forking is required
            // forking: {
            //     url: SEPOLIA_RPC_URL,
            //     accounts: PRIVATE_KEY ? [PRIVATE_KEY, FACTORY_DEPLOYER_PRIVATE_KEY] : [],
            //     blockNumber: FORKING_BLOCK_NUMBER
            // }
        },
        localhost: {
            chainId: 31337,
        },
        mumbai: MUMBAI_DEPLOYMENT_SETTINGS,
        sepolia: SEPOLIA_DEPLOYMENT_SETTINGS,
    },
    defaultNetwork: "hardhat",
    etherscan: {
        apiKey: {
            polygonMumbai: POLYGONSCAN_API_KEY,
            sepolia: ETHERSCAN_API_KEY,
        },
    },
    gasReporter: {
        enabled: REPORT_GAS,
        currency: "USD",
        outputFile: "gas-report.txt",
        noColors: true
    },
    contractSizer: {
        runOnCompile: false,
    },
    paths: {
        sources: "./contracts",
        tests: "./test",
        cache: "./build/cache",
        artifacts: "./build/artifacts",
    },
    namedAccounts: {
        deployer: {
            default: 0,
            31337: 0, 
            80001: 0,
            11155111: 0
        },
        factoryDeployer: {
            31337: 1, 
            80001: 1,
            11155111: 1
        }
    },
    mocha: {
        timeout: 300000, // 300 seconds max for running tests
    },
}