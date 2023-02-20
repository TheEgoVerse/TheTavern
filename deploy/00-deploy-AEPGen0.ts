import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import {
    developmentChains,
    VERIFICATION_BLOCK_CONFIRMATIONS,
    OWNER_WALLET_ADDRESS,
    BASE_URI,
} from "../helper-hardhat-config"
import verify from "../utils/verify"

const deployTavern: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deployments, network, getNamedAccounts } = hre
    const { deployer } = await getNamedAccounts()
    const { deploy, log } = deployments

    const waitBlockConfirmations = developmentChains.includes(network.name)
        ? 1
        : VERIFICATION_BLOCK_CONFIRMATIONS

    // if (developmentChains.includes(network.name)) {
    //     // Write code Specific to Local Network Testing
    // }

    const args: any[] = [BASE_URI, OWNER_WALLET_ADDRESS]

    const nft = await deploy("AEPGen0", {
        from: deployer,
        log: true,
        args: args,
        waitConfirmations: waitBlockConfirmations,
    })

    if (!developmentChains.includes(network.name) && process.env.SNOWTRACE_API_KEY) {
        log("Verifying...")
        await verify(nft.address, args)
    }
}

export default deployTavern
deployTavern.tags = ["all", "nft"]
