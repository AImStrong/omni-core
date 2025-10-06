import { ethers, network } from "hardhat";
import { retryLiquidationCallPhase3 } from "./user-functions/liquidation";

// Script to retry liquidation call phase 3
async function main() {
    const networkName = network.name;
    
    // Get signer
    const accounts = await ethers.getSigners();
    const signer = accounts[2];
    
    // Configuration from environment variables
    const universalMessengerAddress = process.env[`${networkName.toUpperCase()}_UNIVERSAL_MESSENGER_PROXY`] as string;
    if (!universalMessengerAddress) {
        throw new Error(`${networkName.toUpperCase()}_UNIVERSAL_MESSENGER_PROXY not set in environment`);
    }

    const chainId = 97;
    const countId = 1;
    
    const user = '0xa197db02209a1788F220580Dc0794dBdb8be6cc8';

    const data = "0x000000000000000000000000e4b9e96e05b2918588b14406b900ed10edcc45a6000000000000000000000000a197db02209a1788f220580dc0794dbdb8be6cc8000000000000000000000000f59b95ae9ae4da20a36f48151d5574499de73f88000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007492cd3403c153600000000000000000000000000000000000000000000000007492bb268402c00";

    
    console.log("\nChecking gas balance before retry:");
    await checkGasBalance(
        universalMessengerAddress,
        await signer.getAddress(), 
        chainId
    );

    console.log("\nRetrying liquidation call phase 3:");
    console.log("- Universal Messenger:", universalMessengerAddress);
    console.log("- Chain ID:", chainId);
    console.log("- Count ID:", countId);
    console.log("- User:", user);
    console.log("- Data:", data);
    
    try {
        await retryLiquidationCallPhase3(
            universalMessengerAddress,
            chainId,
            countId,
            user,
            data,
            signer
        );
        console.log("Liquidation retry completed successfully!");

    } catch (error) {
        console.error("Error retrying liquidation:", error);
        throw error;
    }
}


async function checkGasBalance(
    universalMessengerAddress: string,
    liquidator: string,
    collateralChainId: number
) {
    const universalMessenger = await ethers.getContractAt("UniversalMessenger", universalMessengerAddress);
    
    // Get gas token for collateral chain
    const systemContract = await ethers.getContractAt("ISystem", await universalMessenger.systemContract());
    const collateralChainGasToken = await systemContract.gasCoinZRC20ByChainId(collateralChainId);
    
    
    // Check gas balance on collateral chain
    const collateralChainGasBalance = await universalMessenger.getUserGasBalance(liquidator, collateralChainGasToken);
    console.log(`Liquidator gas balance on collateral chain (${collateralChainId}):`, ethers.utils.formatEther(collateralChainGasBalance));
    
    return {
        collateralChainGasBalance
    };
}

// Execute the script
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/controller/02-user-scripts/liquidationRetry.ts --network zeta_testnet 