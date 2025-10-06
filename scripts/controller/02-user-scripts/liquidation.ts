import { ethers, network } from "hardhat";
import { 
    liquidationCallPhase1,
    retryLiquidationCallPhase3,
    getFailedLiquidationPhase3Messages
} from "./user-functions/liquidation";

// Script to execute liquidation operations
async function main() {
    await executeLiquidation();
}

// Function to check gas balance
async function checkGasBalance(
    universalMessengerAddress: string,
    liquidator: string,
    debtChainId: number,
    collateralChainId: number
) {
    const universalMessenger = await ethers.getContractAt("UniversalMessenger", universalMessengerAddress);
    
    // Get gas token for debtChain
    const systemContract = await ethers.getContractAt("ISystem", await universalMessenger.systemContract());
    const debtChainGasToken = await systemContract.gasCoinZRC20ByChainId(debtChainId);
    const collateralChainGasToken = await systemContract.gasCoinZRC20ByChainId(collateralChainId);
    
    // Check gas balance on debtChain
    const debtChainGasBalance = await universalMessenger.getUserGasBalance(liquidator, debtChainGasToken);
    console.log(`Liquidator gas balance on debt chain (${debtChainId}):`, ethers.utils.formatEther(debtChainGasBalance));
    
    // Check gas balance on collateralChain
    const collateralChainGasBalance = await universalMessenger.getUserGasBalance(liquidator, collateralChainGasToken);
    console.log(`Liquidator gas balance on collateral chain (${collateralChainId}):`, ethers.utils.formatEther(collateralChainGasBalance));
    
    const debtGasToken = await ethers.getContractAt("IZRC20", debtChainGasToken);
    console.log('Liquidator gas on zrc20 debt token', await debtGasToken.balanceOf(liquidator));

    const collateralGasToken = await ethers.getContractAt("IZRC20", collateralChainGasToken);
    console.log('Liquidator gas on zrc20 collateral token', await collateralGasToken.balanceOf(liquidator));
  
    return {
        debtChainGasBalance,
        collateralChainGasBalance
    };
}

async function executeLiquidation() {
    const networkName = network.name;

    const config = {
        // User to be liquidated
        userToLiquidate: '0xE4b9e96e05b2918588B14406B900Ed10edCC45a6',
        // Liquidator is the signer executing the transaction
        liquidator: '0x135e94c43984B9d4D27B5D663F69a9d31d96f381', 
        debtAsset: '0xF59b95AE9Ae4da20A36f48151D5574499DE73f88',
        collateralAsset: '0xF59b95AE9Ae4da20A36f48151D5574499DE73f88',
        debtChainId: 8453, // Default to bsc testnet
        collateralChainId: 42161,
        debtToCover: ethers.utils.parseEther("1"),
        receiveTToken: false
    }

    const controllerAddress = process.env[`${networkName.toUpperCase()}_CONTROLLER_PROXY`] as string;
    if (!controllerAddress) {
        throw new Error(`${networkName.toUpperCase()}_CONTROLLER_PROXY not set in environment`);
    }

    // Get UniversalMessenger address
    const universalMessengerAddress = process.env[`${networkName.toUpperCase()}_UNIVERSAL_MESSENGER_PROXY`] as string;
    if (!universalMessengerAddress) {
        throw new Error(`${networkName.toUpperCase()}_UNIVERSAL_MESSENGER_PROXY not set in environment`);
    }

    // // Get liquidator signer
    // const accounts = await ethers.getSigners();
    // let i;
    // for (i = 0; i < accounts.length; i++) {
    //     if (accounts[i].address.toLowerCase() === config.liquidator.toLowerCase()) break;
    // }
    // if (i === accounts.length) {
    //     // If no matching account found, use the first account as liquidator
    //     console.log(`No account found matching liquidator address ${config.liquidator}`);
    //     return;
    // }
   
    // const signer = accounts[i];
    // console.log(`Using ${await signer.getAddress()} as liquidator`);

    // // Check liquidator's gas balance
    // console.log("\nChecking gas balance for liquidator before liquidation:");
    await checkGasBalance(
        universalMessengerAddress,
        '0x135e94c43984B9d4D27B5D663F69a9d31d96f381',  // await signer.getAddress(),
        config.debtChainId,
        config.collateralChainId
    );

    // console.log("\nExecuting liquidation call phase 1:");
    // console.log("- Controller:", controllerAddress);
    // console.log("- Debt Asset:", config.debtAsset);
    // console.log("- Collateral Asset:", config.collateralAsset);
    // console.log("- Debt Chain ID:", config.debtChainId);
    // console.log("- Collateral Chain ID:", config.collateralChainId);
    // console.log("- User to liquidate:", config.userToLiquidate);
    // console.log("- Debt to Cover:", ethers.utils.formatEther(config.debtToCover));
    // console.log("- Receive TToken:", config.receiveTToken);
    
    // try {
    //     await liquidationCallPhase1(
    //         controllerAddress,
    //         config.debtAsset,
    //         config.collateralAsset,
    //         config.debtChainId,
    //         config.collateralChainId,
    //         config.userToLiquidate,
    //         config.debtToCover,
    //         config.receiveTToken,
    //         signer
    //     );
    //     console.log("Liquidation call phase 1 completed successfully!");


    // } catch (error) {
    //     console.error("Error executing liquidation:", error);
    //     throw error;
    // }
}

// Execute the script
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 

// npx hardhat run scripts/controller/02-user-scripts/liquidation.ts --network zeta_testnet