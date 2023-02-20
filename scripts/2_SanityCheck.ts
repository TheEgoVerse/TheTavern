import { ethers, network } from "hardhat"
import { takeCoverage } from "v8"
import { AEPGen0, AEPStaking, Prey, Tavern } from "../typechain-types"

async function sanityCheck() {
    const AEPGen0Contract: AEPGen0 = await ethers.getContract("AEPGen0")
    const preyContract: Prey = await ethers.getContract("Prey")
    const AEPStakingContract: AEPStaking = await ethers.getContract("AEPStaking")
    const TavernContract: Tavern = await ethers.getContract("Tavern")

    // Deployer Actions
    const tx = await AEPGen0Contract.baseTokensURI()
    console.log("Token Base URI", tx)

    const tx2 = await AEPGen0Contract.currentTokenId()
    console.log("NFT Minted Count", tx2.toString())

    const tx3 = await preyContract.StakingAddress()
    console.log("Staking Address", tx3)

    const tx4 = await preyContract.GameAddress()
    console.log("Game Address", tx4)

    // const tx5 = await AEPStakingContract.initialised()
    // console.log("Tokens Claimable: ", tx5)

    const tx6 = await AEPStakingContract.tokensClaimable()
    console.log("Tokens Claimable: ", tx6)

    const tx7 = await AEPStakingContract.stakedTotal()
    console.log("Total Staked NFTs: ", tx7.toString())

    const tx8 = await AEPStakingContract.stakingStartTime()
    console.log("Staked Start Time: ", tx8.toString())
}

sanityCheck()
    .then(() => process.exit(0))
    .catch((error: any) => {
        console.error(error)
        process.exit(1)
    })
