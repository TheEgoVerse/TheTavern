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
    43113: {
        name: "avalancheFujiTestnet",
    },
}

export const developmentChains = ["hardhat", "localhost"]
export const VERIFICATION_BLOCK_CONFIRMATIONS = 6

// export const OWNER_WALLET_ADDRESS = "0x820ff74d6992B3169FEA39AEea94423ef245b6eC"
export const OWNER_WALLET_ADDRESS = "0x91C2352245065B9e5d2514a313b60c1f01BfF60F"
export const BASE_URI = "https://alteregopunks.com/nft"
