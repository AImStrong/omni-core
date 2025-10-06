import { ethers, network } from "hardhat";
import { withdrawGasFee } from "./user-functions/withdrawGasFee";

// Script to withdraw gas fee
async function main() {
    const networkName = network.name;

    const config = {
        user: '0xe2dC357BcECFFeb321a8ACc09b6ffcfCbBC335C2',
        chainId: 97, // Default to bsc testnet
        amount: ethers.utils.parseEther("0.001"),
        to: "0xe2dC357BcECFFeb321a8ACc09b6ffcfCbBC335C2"
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
    
    // Set to to signer address if not specified
    if (!config.to) {
        config.to = await signer.getAddress();
    }

    console.log("Withdrawing gas fee:");
    console.log("- Universal Messenger:", universalMessengerAddress);
    console.log("- Chain ID:", config.chainId);
    console.log("- Amount:", ethers.utils.formatEther(config.amount), "tokens");
    console.log("- To:", config.to);
    
    try {
        await withdrawGasFee(
            universalMessengerAddress,
            config.chainId,
            signer,
            config.amount,
            config.to
        );
        console.log("Gas fee withdrawal completed successfully!");
    } catch (error) {
        console.error("Error withdrawing gas fee:", error);
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

// npx hardhat run scripts/controller/02-user-scripts/withdrawGasFee.ts --network zeta_testnet
// npx hardhat run scripts/controller/02-user-scripts/withdrawGasFee.ts --network zeta_mainnet