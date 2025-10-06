import { setPoolImpl } from './pool-functions/set-pool-logic';
import { ethers, network } from 'hardhat';
import * as dotenv from 'dotenv';
dotenv.config();

async function main() {
    // ========= note: increase revision =========

    const networkName = network.name;

    const pool = await ethers.getContractAt('Pool', process.env[`${networkName.toUpperCase()}_POOL_PROXY`]!);
    console.log('current pool revision: ', await pool.POOL_REVISION());
    // await setPoolImpl(null);
    console.log('new pool revision: ', await pool.POOL_REVISION());
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/lending/01-pool-scripts/update-pool-impl.ts --network bsc_testnet
// npx hardhat run scripts/lending/01-pool-scripts/update-pool-impl.ts --network base_mainnet
// npx hardhat run scripts/lending/01-pool-scripts/update-pool-impl.ts --network arbitrum_one_mainnet