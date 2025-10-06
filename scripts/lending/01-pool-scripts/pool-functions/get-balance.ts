import { ethers } from 'hardhat';
import * as dotenv from 'dotenv';
dotenv.config();

async function getBalance(asset: string, account: string) {
    const bep20 = await ethers.getContractAt('BEP20', asset);
    const balance = await bep20.balanceOf(account);

    return balance;
}

async function getTTokenBalance(poolAddress: string, asset: string, account: string) {
    const pool = await ethers.getContractAt("Pool", poolAddress);
    const reserve = await pool.getReserveData(asset);
    
    const tTokenBalance = await getBalance(reserve.tTokenAddress, account);
    return tTokenBalance;
}

async function getDebtTokenBalance(poolAddress: string, asset: string, account: string) {
    const pool = await ethers.getContractAt("Pool", poolAddress);
    const reserve = await pool.getReserveData(asset);
    
    const debtTokenBalance = await getBalance(reserve.variableDebtTokenAddress, account);
    return debtTokenBalance;
}

async function getScaledBalance(asset: string, account: string) {
    const tToken = await ethers.getContractAt('TToken', asset);

    const scaled = await tToken.scaledBalanceOf(account);
    return scaled;
}

export {
    getBalance,
    getTTokenBalance,
    getDebtTokenBalance,
    getScaledBalance
}