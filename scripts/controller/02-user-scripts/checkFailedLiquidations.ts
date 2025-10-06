import { ethers, network } from "hardhat";
import { getFailedLiquidationPhase3Messages } from "./user-functions/liquidation";

// Script to check failed liquidation phase 3 messages
async function main() {
    const networkName = network.name;
    
    // Configuration from environment variables
    const universalMessengerAddress = process.env[`${networkName.toUpperCase()}_UNIVERSAL_MESSENGER_PROXY`] as string;
    if (!universalMessengerAddress) {
        throw new Error(`${networkName.toUpperCase()}_UNIVERSAL_MESSENGER_PROXY not set in environment`);
    }

    const chainId = 97;
    const countId = 0;

    console.log("Checking failed liquidation phase 3 messages:");
    console.log("- Universal Messenger:", universalMessengerAddress);
    console.log("- Chain ID:", chainId);
    console.log("- Count ID:", countId);
    
    try {
        const messageHash = await getFailedLiquidationPhase3Messages(
            universalMessengerAddress,
            chainId,
            countId
        );
        console.log("Message hash retrieval completed successfully!");
        console.log("Message hash:", messageHash);
        return messageHash;
    } catch (error) {
        console.error("Error checking failed liquidations:", error);
        throw error;
    }
}

// Execute the script
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/controller/02-user-scripts/checkFailedLiquidations.ts --network zeta_testnet 