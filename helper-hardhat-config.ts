export interface networkConfigItem {
    name?: string
    initBaseURI?: string
    initNotRevealedUri?: string
}

export interface networkConfigInfo {
    [key: number]: networkConfigItem
}

export const networkConfig: networkConfigInfo = {
    31337: {
        name: "localhost",
    },
    5: {
        name: "goerli",
    },
}

export const developmentChains = ["hardhat", "localhost"]
export const VERIFICATION_BLOCK_CONFIRMATIONS = 6

export const NFT_CONTRACT_ADDRESS = "0xC581CC4582AbD5aA4aB5B6D1F27F71D13518c9dD"
export const PREY_CONTRACT_ADDRESS = "0x830ddEe8f48E183e6B490cf22e10f958FC25Ef39"
export const OWNER_WALLET_ADDRESS = "0x820ff74d6992B3169FEA39AEea94423ef245b6eC "
