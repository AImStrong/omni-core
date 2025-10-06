import { ethers, network } from 'hardhat';
import * as dotenv from 'dotenv';
dotenv.config();

async function configureReserveAsCollateral(chainId: number, asset: string, ltv: number, liquidationThreshold: number, liquidationBonus: number) {
    let networkName = network.name;

    // ========= Contracts required =========
    const controllerConfigurator = await ethers.getContractAt('CrossChainLendingControllerConfigurator', process.env[`${networkName.toUpperCase()}_CONTROLLER_CONFIGURATOR_PROXY`]!);
    const controller = await ethers.getContractAt(`CrossChainLendingController`, process.env[`${networkName.toUpperCase()}_CONTROLLER_PROXY`]!);
    
    // ========= configureReserveAsCollateral =========
    console.log('========= configureReserveAsCollateral =========');

    const tx = await controllerConfigurator.configureReserveAsCollateral(chainId, asset, ltv, liquidationThreshold, liquidationBonus);
    await tx.wait();

    console.log('configureReserveAsCollateral tx hash: ', tx.hash);
    console.log('reserve configuration: ', await controller.getConfiguration(chainId, asset));
}

async function addChainToController(chainId: number) {
    let networkName = network.name;

    // ========= Contracts required =========
    const controllerConfigurator = await ethers.getContractAt('CrossChainLendingControllerConfigurator', process.env[`${networkName.toUpperCase()}_CONTROLLER_CONFIGURATOR_PROXY`]!);
    const controller = await ethers.getContractAt(`CrossChainLendingController`, process.env[`${networkName.toUpperCase()}_CONTROLLER_PROXY`]!);
    
    // ========= addChainToController =========
    console.log('========= addChainToController =========');

    const tx = await controllerConfigurator.addChainToController(chainId);
    await tx.wait();

    console.log('addChainToController tx hash: ', tx.hash);
    console.log('chain info: ', await controller.getPoolInfo(chainId));
}

async function setReserveDecimals(chainId: number, asset: string, decimals: number) { 
    let networkName = network.name;

    // ========= Contracts required ========= 
    const controllerConfigurator = await ethers.getContractAt('CrossChainLendingControllerConfigurator', process.env[`${networkName.toUpperCase()}_CONTROLLER_CONFIGURATOR_PROXY`]!);
    const controller = await ethers.getContractAt(`CrossChainLendingController`, process.env[`${networkName.toUpperCase()}_CONTROLLER_PROXY`]!);
    
    // ========= setReserveDecimals  =========
    console.log('========= setReserveDecimals =========');

    const tx = await controllerConfigurator.setReserveDecimals(chainId, asset, decimals);
    await tx.wait();

    console.log('setReserveDecimals tx hash: ', tx.hash);
    console.log('reserve configuration: ', await controller.getConfiguration(chainId, asset));
}

export {
    configureReserveAsCollateral,
    addChainToController,
    setReserveDecimals
}