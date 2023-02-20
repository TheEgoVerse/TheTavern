import { ethers, network } from "hardhat"
import { AEPGen0, AEPStaking, Prey, Tavern } from "../typechain-types"

async function deployerActions() {
    const AEPGen0Contract: AEPGen0 = await ethers.getContract("AEPGen0")
    const preyContract: Prey = await ethers.getContract("Prey")
    const AEPStakingContract: AEPStaking = await ethers.getContract("AEPStaking")
    const TavernContract: Tavern = await ethers.getContract("Tavern")

    // Deployer Actions
    const tx = await AEPGen0Contract.setMintIsLive()
    await tx.wait(1)

    const tx2 = await preyContract.setStakingAddress(AEPStakingContract.address)
    await tx2.wait(1)

    const tx3 = await preyContract.setGameAddress(TavernContract.address)
    await tx3.wait(1)

    const tx4 = await AEPStakingContract.initStaking()
    await tx4.wait(1)

    const tx5 = await AEPStakingContract.setTokensClaimable(true)
    await tx5.wait(1)
}

deployerActions()
    .then(() => process.exit(0))
    .catch((error: any) => {
        console.error(error)
        process.exit(1)
    })
