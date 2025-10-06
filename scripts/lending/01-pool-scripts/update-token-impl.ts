import {
    UpdateTTokenInput,
    UpdateDebtTokenInput,
    updateTToken,
    updateDebtToken
} from './pool-functions/set-token-logic';
import { ethers, network } from 'hardhat';
import * as dotenv from 'dotenv';
dotenv.config();

const config = {
    asset: '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913',
    name: 'Wrapped ETH',
    treasury: '0x81ff99181d4Bdd14f64dC1a0e1A98EF81688bA0a',
    incentivesController: '0x0000000000000000000000000000000000000000',
}

const tToken: UpdateTTokenInput = {
    asset: config.asset,
    treasury: config.treasury,
    incentivesController: config.incentivesController,
    name: "AImstrong interest bearing " + config.name,
    symbol: "t" + config.name,
    implementation: null,
    params: "0x12"
}

const debtToken: UpdateDebtTokenInput = {
    asset: config.asset,
    incentivesController: config.incentivesController,
    name: "AImstrong debt bearing " + config.name,
    symbol: "debt" + config.name,
    implementation: null,
    params: "0x12"
}

async function main() {

    // await updateTToken(tToken);
    // await updateDebtToken(debtToken);

    const networkName = network.name;

    const pool = await ethers.getContractAt("Pool", process.env[`${networkName.toUpperCase()}_POOL_PROXY`]!);
    const reserveData = await pool.getReserveData(config.asset);
    const token = await ethers.getContractAt("TToken", reserveData.tTokenAddress);

    console.log('treasury: ', await token.RESERVE_TREASURY_ADDRESS());
    console.log('incentives controller: ', await token.getIncentivesController());
    console.log('name: ', await token.name());
    console.log('symbol: ', await token.symbol());
    console.log('decimals: ', await token.decimals());
    console.log('total supply: ', await token.totalSupply());
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/lending/01-pool-scripts/update-token-impl.ts --network bsc_testnet
// npx hardhat run scripts/lending/01-pool-scripts/update-token-impl.ts --network arbitrum_one_mainnet
// npx hardhat run scripts/lending/01-pool-scripts/update-token-impl.ts --network base_mainnet
// npx hardhat run scripts/lending/01-pool-scripts/update-token-impl.ts --network bsc_mainnet