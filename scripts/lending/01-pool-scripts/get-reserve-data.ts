import { decodeConfiguration } from './pool-functions/decode-configuration';
import { ethers, network } from 'hardhat';
import * as dotenv from 'dotenv';
import { BigNumber } from 'ethers';
dotenv.config();

const config = {
    asset: '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913',
}

async function main() {
    let networkName = network.name;

    const pool = await ethers.getContractAt("Pool", process.env[`${networkName.toUpperCase()}_POOL_PROXY`]!);
    const bep20 = await ethers.getContractAt("BEP20", config.asset);

    const data = await pool.getReserveData(config.asset);
    console.log(data);
    // console.log('underlying balance: ', await bep20.balanceOf(data.tTokenAddress));

    // const tToken = await ethers.getContractAt("TToken", data.tTokenAddress);
    // const dToken = await ethers.getContractAt("VariableDebtToken", data.variableDebtTokenAddress);

    // console.log('tToken name: ', await tToken.name());
    // console.log('tToken symbol: ', await tToken.symbol());
    // console.log('dToken name: ', await dToken.name());
    // console.log('dToken symbol: ', await dToken.symbol());
    // console.log('treasury address: ', await tToken.RESERVE_TREASURY_ADDRESS());
    // console.log('tToken total supply: ', await tToken.totalSupply());
    // console.log('tToken total scaled supply: ', await tToken.scaledTotalSupply());
    // console.log('dToken total scaled supply: ', await dToken.scaledTotalSupply());
    // console.log('dToken total supply: ', await dToken.totalSupply());

    // const {
    //     decimals,
    //     isActive,
    //     isFrozen,
    //     borrowingEnabled,
    //     stableBorrowingEnabled,
    //     reserveFactor,
    // } = decodeConfiguration(BigNumber.from(data.configuration.data));

    // console.log("decimals: ", decimals);
    // console.log("isActive: ", isActive);
    // console.log("isFrozen: ", isFrozen);
    // console.log("borrowingEnabled: ", borrowingEnabled);
    // console.log("stableBorrowingEnabled: ", stableBorrowingEnabled);
    // console.log("reserveFactor: ", reserveFactor);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/lending/01-pool-scripts/get-reserve-data.ts --network bsc_testnet
// npx hardhat run scripts/lending/01-pool-scripts/get-reserve-data.ts --network arbitrum_one_mainnet
// npx hardhat run scripts/lending/01-pool-scripts/get-reserve-data.ts --network base_mainnet
// npx hardhat run scripts/lending/01-pool-scripts/get-reserve-data.ts --network bsc_mainnet