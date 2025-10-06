import { ethers } from 'hardhat';
import { encode } from '../../../utils/encode';
import * as dotenv from 'dotenv';
dotenv.config();

async function setReserveInterestRateStrategyAddress(asset: string, rateStrategyAddress: string) {
    // ========= setReserveInterestRateStrategyAddress =========
    console.log("========= setReserveInterestRateStrategyAddress =========");

    const configReserveData = encode("setReserveInterestRateStrategyAddress(address, address)", [
        asset, rateStrategyAddress
    ]);

    console.log(configReserveData);
}

async function setReserveFactor(asset: string, reserveFactor: number) {
    // ========= setReserveFactor =========
    console.log("========= setReserveFactor =========");

    const configReserveData = encode("setReserveFactor(address, uint256)", [
        asset, reserveFactor
    ]);

    console.log(configReserveData);
}

async function setReserveDecimals(asset: string, decimals: number) {
    // ========= setReserveDecimals =========
    console.log("========= setReserveDecimals =========");

    const configReserveData = encode("setReserveDecimals(address, uint256)", [
        asset, decimals
    ]);

    console.log(configReserveData);
}

export {
    setReserveInterestRateStrategyAddress,
    setReserveFactor,
    setReserveDecimals
}