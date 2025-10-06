import { setReserveInterestRateStrategyAddress, setReserveFactor, setReserveDecimals } from './pool-functions/config-reserve';
import { ethers, network } from 'hardhat';
import BigNumber from 'bignumber.js';
import { oneRay } from '../../config/constant';
import * as dotenv from 'dotenv';
dotenv.config();

const config = {
    asset: '0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c',
    reserveFactor: 2000,
    // decimals: 6
}

async function main() {
    // const networkName = network.name;

    // const RateMode = await ethers.getContractFactory("ReserveInterestRateStrategy");
    // const rateMode = await RateMode.deploy(
    //     process.env[`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_PROXY`]!,
    //     new BigNumber(0.9).multipliedBy(oneRay).toFixed(),
    //     0,
    //     new BigNumber(0.055).multipliedBy(oneRay).toFixed(),
    //     new BigNumber(0.4).multipliedBy(oneRay).toFixed()
    // );
    // await rateMode.deployed();
    // console.log("rate mode address: ", rateMode.address);
    // await setReserveInterestRateStrategyAddress(config.asset, rateMode.address);
    await setReserveFactor(config.asset, config.reserveFactor);
    // await setReserveDecimals(config.asset, config.decimals);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/lending/01-pool-scripts/set-reserve-data.ts --network bsc_testnet
// npx hardhat run scripts/lending/01-pool-scripts/set-reserve-data.ts --network arbitrum_one_mainnet
// npx hardhat run scripts/lending/01-pool-scripts/set-reserve-data.ts --network base_mainnet
// npx hardhat run scripts/lending/01-pool-scripts/set-reserve-data.ts --network bsc_mainnet