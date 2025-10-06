import { getBalance, getTTokenBalance, getDebtTokenBalance, getScaledBalance } from './pool-functions/get-balance';
import { ethers, network } from 'hardhat';
import * as dotenv from 'dotenv';
dotenv.config();

const config = {
    user: '0x86A36A5baAa5C60036e758CAa1a4dAd32E6a5af4',
    asset: '0x4200000000000000000000000000000000000006',
}

async function main() {
    let networkName = network.name;

    const pool = await ethers.getContractAt("Pool", process.env[`${networkName.toUpperCase()}_POOL_PROXY`]!);
    const reserve = await pool.getReserveData(config.asset);
    const tToken = await ethers.getContractAt("BEP20", reserve.tTokenAddress);
    const debtToken = await ethers.getContractAt("BEP20", reserve.variableDebtTokenAddress);
    
    console.log(`user ${config.user} underlying balance: `, await getBalance(config.asset, config.user));
    
    console.log(`user ${config.user} tToken: `, await getTTokenBalance(pool.address, config.asset, config.user));
    console.log(`user ${config.user} scaled tToken: `, await getScaledBalance(reserve.tTokenAddress, config.user));
    // console.log(`total supply: `, await tToken.totalSupply());
    
    console.log(`user ${config.user} debtToken: `, await getDebtTokenBalance(pool.address, config.asset, config.user));
    console.log(`user ${config.user} scaled debtToken: `, await getScaledBalance(reserve.variableDebtTokenAddress, config.user));
    // console.log(`total borrow: `, await debtToken.totalSupply());
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/lending/01-pool-scripts/get-user-data.ts --network bsc_testnet
// npx hardhat run scripts/lending/01-pool-scripts/get-user-data.ts --network base_mainnet
// npx hardhat run scripts/lending/01-pool-scripts/get-user-data.ts --network arbitrum_one_mainnet
// npx hardhat run scripts/lending/01-pool-scripts/get-user-data.ts --network bsc_mainnet