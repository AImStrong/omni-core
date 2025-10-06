import { ethers, network } from "hardhat";
import { supplyGasFee } from "./user-functions/supplyGasFee";

// Script to supply gas fee
async function main() {
    const networkName = network.name;

    const config = {
        user: '0xe2dC357BcECFFeb321a8ACc09b6ffcfCbBC335C2',
        chainId: 97, // Default to bsc testnet
        amount:  ethers.utils.parseEther("1.0"),
        onBehalfOf: "0xe2dC357BcECFFeb321a8ACc09b6ffcfCbBC335C2"
    }

    const universalMessengerAddress = process.env[`${networkName.toUpperCase()}_UNIVERSAL_MESSENGER_PROXY`] as string;
    if (!universalMessengerAddress) {
        throw new Error(`${networkName.toUpperCase()}_UNIVERSAL_MESSENGER_PROXY not set in environment`);
    }

    // Get signer
    const accounts = await ethers.getSigners();
    let i;
    for (i = 0; i < accounts.length; i++) {
        if (accounts[i].address === config.user) break;
    }
    if (i === accounts.length) return console.log('no accounts');
    const signer = accounts[i];
    
    // Set onBehalfOf to signer address if not specified
    if (!config.onBehalfOf) {
        config.onBehalfOf = await signer.getAddress();
    }

    console.log("Supplying gas fee:");
    console.log("- Universal Messenger:", universalMessengerAddress);
    console.log("- Chain ID:", config.chainId);
    console.log("- Amount:", ethers.utils.formatEther(config.amount), "tokens");
    console.log("- On behalf of:", config.onBehalfOf);
    
    try {
        await supplyGasFee(
            universalMessengerAddress,
            config.chainId,
            signer,
            config.amount,
            config.onBehalfOf
        );
        console.log("Gas fee supply completed successfully!");
    } catch (error) {
        console.error("Error supplying gas fee:", error);
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

// npx hardhat run scripts/controller/02-user-scripts/supplyGasFee.ts --network zeta_testnet