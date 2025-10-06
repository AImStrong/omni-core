import BigNumber from 'bignumber.js';
import { oneRay } from '../../config/constant';
import { addReserves, dropReserve } from './pool-functions/add-reserve';
import { ethers, network } from 'hardhat';
import * as dotenv from 'dotenv';
dotenv.config();

async function main() {

    let networkName = network.name;
    await addReserves(['WBTC']);

    // const pool = await ethers.getContractAt("Pool", process.env[`${networkName.toUpperCase()}_POOL_PROXY`]!);
    // console.log('reserves list: ', await pool.getReservesList()); 
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/lending/01-pool-scripts/add-reserve.ts --network bsc_testnet
// npx hardhat run scripts/lending/01-pool-scripts/add-reserve.ts --network arbitrum_one_mainnet
// npx hardhat run scripts/lending/01-pool-scripts/add-reserve.ts --network base_mainnet
// npx hardhat run scripts/lending/01-pool-scripts/add-reserve.ts --network bsc_mainnet