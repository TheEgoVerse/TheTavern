import { HardhatUserConfig } from "hardhat/config"
import "@nomicfoundation/hardhat-toolbox"
import "hardhat-deploy"
import "hardhat-contract-sizer"
import "dotenv/config"
import "@openzeppelin/hardhat-upgrades"

const PRIVATE_KEY = process.env.PRIVATE_KEY || ""
const PRIVATE_KEY2 = process.env.PRIVATE_KEY2 || ""
const FUJI_RPC_URL = process.env.FUJI_RPC_URL || ""
const SNOWTRACE_API_KEY = process.env.SNOWTRACE_API_KEY || ""

const config: HardhatUserConfig = {
    solidity: {
        compilers: [
            {
                version: "0.8.17",
            },
        ],
    },
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            chainId: 31337,
        },
        localhost: {
            chainId: 31337,
        },
        avalancheFujiTestnet: {
            url: FUJI_RPC_URL,
            accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY, PRIVATE_KEY2] : [],
            saveDeployments: true,
            chainId: 43113,
        },
    },
    etherscan: {
        // npx hardhat verify --network <NETWORK> <CONTRACT_ADDRESS> <CONSTRUCTOR_PARAMETERS>
        apiKey: {
            // rinkeby: ETHERSCAN_API_KEY,
            // kovan: ETHERSCAN_API_KEY,
            // goerli: ETHERSCAN_API_KEY,
            // avalanche: SNOWTRACE_API_KEY,
            avalancheFujiTestnet: SNOWTRACE_API_KEY,
            // polygon: POLYGONSCAN_API_KEY,
        },
    },

    gasReporter: {
        enabled: false,
        currency: "USD",
        outputFile: "gas-report.txt",
        noColors: true,
        coinmarketcap: process.env.COINMARKETCAP_API_KEY,
        token: "AVAX",
    },
    namedAccounts: {
        deployer: {
            default: 0,
        },
        player: {
            default: 1,
        },
    },
    mocha: {
        timeout: 300000, // 200 Seconds
    },
}

export default config
