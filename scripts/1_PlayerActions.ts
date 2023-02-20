import { ethers, network } from "hardhat"
import { AEPGen0, AEPStaking, Prey, Tavern } from "../typechain-types"

async function playerActions() {
    const HUMAN_NFT_PRICE = ethers.utils.parseUnits("0.25")
    const ZOMBIE_NFT_PRICE = ethers.utils.parseUnits("0.5")
    const VAMPIRE_NFT_PRICE = ethers.utils.parseUnits("0.75")

    const accounts = await ethers.getSigners()

    const deployer = accounts[0]
    const player = accounts[1]

    const AEPGen0Contract: AEPGen0 = await ethers.getContract("AEPGen0")
    // const preyContract: Prey = await ethers.getContract("Prey")
    const AEPStakingContract: AEPStaking = await ethers.getContract("AEPStaking")
    // const TavernContract: Tavern = await ethers.getContract("Tavern")

    // Player Actions
    const AEPGen0PlayerConnect: AEPGen0 = await AEPGen0Contract.connect(player)
    const AEPStakingPlayerConnect: AEPStaking = await AEPStakingContract.connect(player)

    const tx6 = await AEPGen0PlayerConnect.mintHumanNFT({ value: HUMAN_NFT_PRICE })
    await tx6.wait(1)
    const tx7 = await AEPGen0PlayerConnect.mintZombieNFT({ value: ZOMBIE_NFT_PRICE })
    await tx7.wait(1)
    const tx8 = await AEPGen0PlayerConnect.mintVampireNFT({ value: VAMPIRE_NFT_PRICE })
    await tx8.wait(1)

    const tx9 = await AEPStakingPlayerConnect.stakeBatch([1, 2, 3])
    await tx9.wait(1)
}

playerActions()
    .then(() => process.exit(0))
    .catch((error: any) => {
        console.error(error)
        process.exit(1)
    })
