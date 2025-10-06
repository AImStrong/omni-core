import { updateConfiguratorImpl } from './controller-functions/update-configurator-impl';
import { ethers, network } from 'hardhat';
import * as dotenv from 'dotenv';
dotenv.config();

const config = {
    // Set to null to deploy new implementation, or provide the address of an existing implementation
    newConfiguratorImpl: null
}

async function main() {
    const networkName = network.name;

    const controllerConfig = await ethers.getContractAt('CrossChainLendingControllerConfigurator', process.env[`${networkName.toUpperCase()}_CONTROLLER_CONFIGURATOR_PROXY`]!);
    console.log('controller configurator current revision: ', await controllerConfig.CONFIGURATOR_REVISION());

    await updateConfiguratorImpl(config.newConfiguratorImpl);

    console.log('controller configurator new revision: ', await controllerConfig.CONFIGURATOR_REVISION());
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/controller/01-controller-scripts/update-configurator-impl.ts --network zeta_testnet
// npx hardhat run scripts/controller/01-controller-scripts/update-configurator-impl.ts --network zeta_mainnet