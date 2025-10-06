import { ethers, network } from "hardhat";
import { transferGasFee } from "./user-functions/transferGasFee";

// Script to transfer gas fee
async function main() {
    const networkName = network.name;

    const config = {
        user: '0xe2dC357BcECFFeb321a8ACc09b6ffcfCbBC335C2',
        chainId: 97, // Default to bsc testnet
        amount: ethers.utils.parseEther("0.00084"),
        to: "0xa197db02209a1788F220580Dc0794dBdb8be6cc8" // Change this to the recipient address
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
    
    // Ensure to address is specified and different from sender
    if (!config.to || config.to === await signer.getAddress()) {
        throw new Error("Recipient address must be specified and different from sender");
    }

    console.log("Transferring gas fee:");
    console.log("- Universal Messenger:", universalMessengerAddress);
    console.log("- Chain ID:", config.chainId);
    console.log("- Amount:", config.amount.toString(), "tokens");
    console.log("- From:", await signer.getAddress());
    console.log("- To:", config.to);
    
    try {
        await transferGasFee(
            universalMessengerAddress,
            config.chainId,
            signer,
            config.amount,
            config.to
        );
        console.log("Gas fee transfer completed successfully!");
    } catch (error) {
        console.error("Error transferring gas fee:", error);
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

// npx hardhat run scripts/controller/02-user-scripts/transferGasFee.ts --network zeta_testnet 