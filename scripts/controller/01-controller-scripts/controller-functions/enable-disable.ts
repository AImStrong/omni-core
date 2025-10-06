import { ethers, network } from 'hardhat';
import { encode } from '../../../utils/encode';
import * as dotenv from 'dotenv';
import { decodeConfiguration } from './decode-configuration';
dotenv.config();

async function setReserveActive(chainId: number, asset: string, active: boolean) { 
    let networkName = network.name;

    // ========= Contracts required ========= 
    const controllerConfigurator = await ethers.getContractAt('CrossChainLendingControllerConfigurator', process.env[`${networkName.toUpperCase()}_CONTROLLER_CONFIGURATOR_PROXY`]!);
    const controller = await ethers.getContractAt(`CrossChainLendingController`, process.env[`${networkName.toUpperCase()}_CONTROLLER_PROXY`]!);
    
    // ========= setReserveActive =========
    console.log('========= setReserveActive =========');

    const data = encode('setReserveActive(uint256,address,bool)', [chainId, asset, active]);
    console.log(data);

    const reserveData = await controller.getReserveData(chainId, asset);
    const decodedConfig = decodeConfiguration(reserveData.configuration.data);
    console.log('active: ', decodedConfig.isActive);
}

async function setReserveBorrowingEnabled(chainId: number, asset: string, variableBorrowRateEnabled: boolean, stableBorrowRateEnabled: boolean) { 
    let networkName = network.name;

    // ========= Contracts required ========= 
    const controllerConfigurator = await ethers.getContractAt('CrossChainLendingControllerConfigurator', process.env[`${networkName.toUpperCase()}_CONTROLLER_CONFIGURATOR_PROXY`]!);
    const controller = await ethers.getContractAt(`CrossChainLendingController`, process.env[`${networkName.toUpperCase()}_CONTROLLER_PROXY`]!);
    
    // ========= setReserveBorrowingEnabled  =========
    console.log('========= enableBorrowingOnReserve =========');

    const data = encode('setReserveBorrowingEnabled(uint256,address,bool,bool)', [chainId, asset, variableBorrowRateEnabled, stableBorrowRateEnabled]);
    console.log(data);

    const reserveData = await controller.getReserveData(chainId, asset);
    const decodedConfig = decodeConfiguration(reserveData.configuration.data);
    console.log('borrowing enable: ', decodedConfig.borrowingEnabled);
}

async function setReserveFrozen(chainId: number, asset: string, freeze: boolean) { 
    let networkName = network.name;

    // ========= Contracts required ========= 
    const controllerConfigurator = await ethers.getContractAt('CrossChainLendingControllerConfigurator', process.env[`${networkName.toUpperCase()}_CONTROLLER_CONFIGURATOR_PROXY`]!);
    const controller = await ethers.getContractAt(`CrossChainLendingController`, process.env[`${networkName.toUpperCase()}_CONTROLLER_PROXY`]!);
    
    // ========= freezeReserve  =========
    console.log('========= freezeReserve =========');

    const data = encode('setReserveFrozen(uint256,address,bool)', [chainId, asset, freeze]);
    console.log(data);

    const reserveData = await controller.getReserveData(chainId, asset);
    const decodedConfig = decodeConfiguration(reserveData.configuration.data);
    console.log('frozen: ', decodedConfig.isFrozen);
}

async function setPoolPause(chainId: number, val: boolean) { 
    let networkName = network.name;

    // ========= Contracts required ========= 
    const controllerConfigurator = await ethers.getContractAt('CrossChainLendingControllerConfigurator', process.env[`${networkName.toUpperCase()}_CONTROLLER_CONFIGURATOR_PROXY`]!);
    const controller = await ethers.getContractAt(`CrossChainLendingController`, process.env[`${networkName.toUpperCase()}_CONTROLLER_PROXY`]!);
    
    // ========= setPoolPause  =========
    console.log('========= setPoolPause =========');

    const data = encode('setPoolPause(uint256,bool)', [chainId, val]);
    console.log(data);

    console.log('pool paused: ', await controller.paused(chainId));
}

async function setControllerPause(val: boolean) { 
    let networkName = network.name;

    // ========= Contracts required ========= 
    const controllerConfigurator = await ethers.getContractAt('CrossChainLendingControllerConfigurator', process.env[`${networkName.toUpperCase()}_CONTROLLER_CONFIGURATOR_PROXY`]!);
    const controller = await ethers.getContractAt(`CrossChainLendingController`, process.env[`${networkName.toUpperCase()}_CONTROLLER_PROXY`]!);
    
    // ========= setControllerPause  =========
    console.log('========= setControllerPause =========');

    const data = encode('setControllerPause(bool)', [val]);
    console.log(data);

    console.log('controller paused: ', await controller.getPauseController());
}

export {
    setReserveActive,
    setReserveBorrowingEnabled,
    setReserveFrozen,
    setPoolPause,
    setControllerPause
}