import { ethers, network } from 'hardhat';
import { encode } from '../../../utils/encode';
import { decodeConfiguration } from './decode-configuration';
import * as dotenv from 'dotenv';
dotenv.config();

async function setReserveActive(asset: string, active: boolean) { 
    let networkName = network.name;
    
    // ========= setReserveActive =========
    console.log("========= setReserveActive =========");

    const configReserveData = encode("setReserveActive(address, bool)", [asset, active]);
    console.log(configReserveData);

    const pool = await ethers.getContractAt("Pool", process.env[`${networkName.toUpperCase()}_POOL_PROXY`]!);
    const reserveData = await pool.getReserveData(asset);
    const decodedConfig = decodeConfiguration(reserveData.configuration.data);

    console.log("new reserve active: ", decodedConfig.isActive);
    console.log("\n");
}

async function setReserveFrozen(asset: string, frozen: boolean) {
    let networkName = network.name;
    
    // ========= setReserveFrozen =========
    console.log("========= setReserveFrozen =========");

    const configReserveData = encode("setReserveFrozen(address, bool)", [asset, frozen]);
    console.log(configReserveData);

    const pool = await ethers.getContractAt("Pool", process.env[`${networkName.toUpperCase()}_POOL_PROXY`]!);
    const reserveData = await pool.getReserveData(asset);
    const decodedConfig = decodeConfiguration(reserveData.configuration.data);

    console.log("new reserve frozen: ", decodedConfig.isFrozen);
    console.log("\n");
}

async function setReserveBorrowingEnabled(asset: string, variableBorrowRateEnabled: boolean, stableBorrowRateEnabled: boolean) {
    let networkName = network.name;
    
    // ========= setReserveBorrowingEnabled =========
    console.log("========= setReserveBorrowingEnabled =========");

    const configReserveData = encode("setReserveBorrowingEnabled(address, bool, bool)", [asset, variableBorrowRateEnabled, stableBorrowRateEnabled]);
    console.log(configReserveData);
    
    const pool = await ethers.getContractAt("Pool", process.env[`${networkName.toUpperCase()}_POOL_PROXY`]!);
    const reserveData = await pool.getReserveData(asset);
    const decodedConfig = decodeConfiguration(reserveData.configuration.data);

    console.log("new reserve borrow enable: ", decodedConfig.borrowingEnabled);
    console.log("\n");
}

async function setPoolPause(val: boolean) {
    let networkName = network.name;
    
    // ========= setPoolPause =========
    console.log("========= setPoolPause =========");

    const configReserveData = encode("setPoolPause(bool)", [val]);
    console.log(configReserveData);

    const pool = await ethers.getContractAt("Pool", process.env[`${networkName.toUpperCase()}_POOL_PROXY`]!);
    const check = await pool.paused();

    console.log("pool paused: ", check);
}

export {
    setReserveActive,
    setReserveFrozen,
    setReserveBorrowingEnabled,
    setPoolPause
}