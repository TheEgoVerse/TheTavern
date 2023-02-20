import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import { developmentChains, VERIFICATION_BLOCK_CONFIRMATIONS } from "../helper-hardhat-config"
import verify from "../utils/verify"
import { ethers } from "hardhat"

const deployTavern: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deployments, network, getNamedAccounts } = hre
    const { deployer } = await getNamedAccounts()
    const { deploy, log } = deployments
    const chainId = network.config.chainId || 31337

    const waitBlockConfirmations = developmentChains.includes(network.name)
        ? 1
        : VERIFICATION_BLOCK_CONFIRMATIONS

    // if (developmentChains.includes(network.name)) {
    //     // Write code Specific to Local Network Testing
    // }
    const aepGen0NFTContract = await ethers.getContract("AEPGen0")
    const preyContract = await ethers.getContract("Prey")
    const args: any[] = [aepGen0NFTContract.address, preyContract.address]

    const aepStaking = await deploy("AEPStaking", {
        from: deployer,
        log: true,
        args: args,
        waitConfirmations: waitBlockConfirmations,
    })

    if (!developmentChains.includes(network.name) && process.env.SNOWTRACE_API_KEY) {
        log("Verifying...")
        await verify(aepStaking.address, args)
    }
}

export default deployTavern
deployTavern.tags = ["all", "staking"]
