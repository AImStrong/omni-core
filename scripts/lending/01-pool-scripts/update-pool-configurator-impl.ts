import { setPoolConfiguratorImpl } from './pool-functions/set-pool-logic';
import { ethers, network } from 'hardhat';
import * as dotenv from 'dotenv';
dotenv.config();

async function main() {
    // ========= note: increase revision =========

    const networkName = network.name;

    const poolConfig = await ethers.getContractAt('PoolConfigurator', process.env[`${networkName.toUpperCase()}_POOL_CONFIGURATOR_PROXY`]!);
    console.log('current pool configurator revision: ', await poolConfig.CONFIGURATOR_REVISION());
    // await setPoolConfiguratorImpl(null);
    console.log('new pool configurator revision: ', await poolConfig.CONFIGURATOR_REVISION());

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/lending/01-pool-scripts/update-pool-configurator-impl.ts --network bsc_testnet
// npx hardhat run scripts/lending/01-pool-scripts/update-pool-configurator-impl.ts --network base_mainnet
// npx hardhat run scripts/lending/01-pool-scripts/update-pool-configurator-impl.ts --network arbitrum_one_mainnet