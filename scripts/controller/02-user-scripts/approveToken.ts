import { ethers, network } from "hardhat";
import { approveToken } from "./user-functions/approveToken";

// Script to approve tokens for pool
async function main() {
    const networkName = network.name;

    // Configuration from environment variables or defaults
    const config = {
       
        user: '0xe2dC357BcECFFeb321a8ACc09b6ffcfCbBC335C2',
        
        // Token address to approve
        tokenAddress: '0xE090a7CA686D94B69617EA1F3E177e00A21c55B7',
        
        // Pool address to approve for
        poolAddress: process.env[`${networkName.toUpperCase()}_POOL_PROXY`]!,
        
        // Amount to approve
        amount: ethers.utils.parseEther("0.1"),
    };

    // Validate config
    if (!config.tokenAddress) {
        throw new Error("TOKEN_ADDRESS not set in environment");
    }

    if (!config.poolAddress) {
        throw new Error("POOL_ADDRESS not set in environment");
    }

    // Get signer
    const accounts = await ethers.getSigners();
    let i;
    for (i = 0; i < accounts.length; i++) {
        if (accounts[i].address.toLowerCase() === config.user.toLowerCase()) break;
    }
    if (i === accounts.length) {
        throw new Error(`No matching account found for address ${config.user}`);
    }
    const signer = accounts[i];

    // Check token balance before approval
    const token = await ethers.getContractAt("IBEP20", config.tokenAddress);
    const balance = await token.balanceOf(signer.address);
    console.log("\nCurrent token balance:", ethers.utils.formatEther(balance));

    // Check allowance before approval
    const allowanceBefore = await token.allowance(signer.address, config.poolAddress);
    console.log("\nCurrent allowance:", ethers.utils.formatEther(allowanceBefore));

    if (!config.amount.eq(ethers.constants.MaxUint256) && balance.lt(config.amount)) {
        throw new Error(`Insufficient token balance. Required: ${ethers.utils.formatEther(config.amount)}, Available: ${ethers.utils.formatEther(balance)}`);
    }
    
    console.log("\nApproving tokens for pool:");
    console.log("- Network:", networkName);
    console.log("- Token address:", config.tokenAddress);
    console.log("- Pool address:", config.poolAddress);
    console.log("- User address:", signer.address);
    console.log("- Amount:", config.amount.eq(ethers.constants.MaxUint256) 
        ? "MAX (unlimited)" 
        : ethers.utils.formatEther(config.amount));
    
    try {
        await approveToken(
            config.tokenAddress,
            config.poolAddress,
            signer,
            config.amount
        );
        console.log("Token approval completed successfully!");

        // Check allowance after approval
        const allowanceAfter = await token.allowance(signer.address, config.poolAddress);
        console.log("\nNew allowance:", ethers.utils.formatEther(allowanceAfter));
    } catch (error) {
        console.error("Error approving tokens:", error);
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

// npx hardhat run scripts/controller/02-user-scripts/approveToken.ts --network bsc_testnet