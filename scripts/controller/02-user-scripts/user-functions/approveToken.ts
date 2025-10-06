import { ethers } from "hardhat";
import { BigNumber } from "ethers";

/**
 * Function to approve tokens for the pool
 * @param tokenAddress The address of the token to approve
 * @param poolAddress The address of the pool to approve tokens for
 * @param account The signer account
 * @param amount The amount to approve
 */
export async function approveToken(
    tokenAddress: string,
    poolAddress: string,
    account: any,
    amount: BigNumber
) {
    console.log(`Approving ${ethers.utils.formatEther(amount)} tokens at ${tokenAddress} for pool ${poolAddress}`);
    
    // Get the token contract
    const bep20 = await ethers.getContractAt("IBEP20", tokenAddress);
    
    // Approve tokens for pool
    const approveTx = await bep20.connect(account).approve(poolAddress, amount);
    await approveTx.wait();
    console.log('Approve tx hash: ', approveTx.hash);
    
    // Get allowance to confirm
    const allowance = await bep20.allowance(account.address, poolAddress);
    console.log(`New allowance: ${ethers.utils.formatEther(allowance)}`);
    
    return {
        txHash: approveTx.hash,
        allowance
    };
} 