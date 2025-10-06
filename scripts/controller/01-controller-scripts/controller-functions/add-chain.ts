import { ethers, network } from 'hardhat';
import { encode } from '../../../utils/encode';
import * as dotenv from 'dotenv';
dotenv.config();

async function addChainToController(chainId: number) {
    let networkName = network.name;

    // ========= Contracts required =========
    const controllerConfigurator = await ethers.getContractAt('CrossChainLendingControllerConfigurator', process.env[`${networkName.toUpperCase()}_CONTROLLER_CONFIGURATOR_PROXY`]!);
    const controller = await ethers.getContractAt(`CrossChainLendingController`, process.env[`${networkName.toUpperCase()}_CONTROLLER_PROXY`]!);

    console.log(`========= Adding chain ${chainId} to controller =========`);

    // Call addChainToController function on the configurator
    // const addChainTx = await controllerConfigurator.addChainToController(chainId);
    // await addChainTx.wait();
    // console.log('addChainToController tx hash: ', addChainTx.hash);

    let data = encode("addChainToController(uint256)", [chainId]);
    console.log(data);

    console.log(`========= Chain ${chainId} added successfully =========`);

    // Get Pool Info to verify the chain was added
    const [reservesCount, paused, maxNumberOfReserves] = await controller.getPoolInfo(chainId);
    console.log("\nPool Information for Chain", chainId);
    console.log("- Reserves Count:", reservesCount.toString());
    console.log("- Paused:", paused);
    console.log("- Max Number of Reserves:", maxNumberOfReserves.toString());
}

export {
    addChainToController
} 