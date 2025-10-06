import { ethers, network } from 'hardhat';
import { writeToEnvFile } from '../../utils/helper';
import { execute } from '../../utils/multisig';
import { encode } from '../../utils/encode';
import * as dotenv from 'dotenv';
dotenv.config();

async function deploy() {
    let networkName = network.name;
    const addressesProvider = await ethers.getContractAt(`contracts/lending-protocol/factory/AddressesProvider.sol:AddressesProvider`, process.env[`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_PROXY`]!);

    // ========= Deploy pool logic =========
    console.log(`========= Deploy Pool Logic =========`);

    // ========= Pool logic =========
    // const LendingPoolLogic = await ethers.getContractFactory('Pool', {
    //     libraries: {
    //         SupplyLogic:      process.env[`${networkName.toUpperCase()}_SUPPLY_LOGIC`]!,
    //         BorrowLogic:      process.env[`${networkName.toUpperCase()}_BORROW_LOGIC`]!,
    //         LiquidationLogic: process.env[`${networkName.toUpperCase()}_LIQUIDATION_LOGIC`]!,
    //         PoolLogic:        process.env[`${networkName.toUpperCase()}_POOL_LOGIC`]!,
    //     }
    // });
    // const lendingPoolLogic = await LendingPoolLogic.deploy();
    // await lendingPoolLogic.deployed();

    // console.log(`${networkName.toUpperCase()}_LENDING_POOL_LOGIC address: `, lendingPoolLogic.address);
    // writeToEnvFile(`${networkName.toUpperCase()}_LENDING_POOL_LOGIC`, lendingPoolLogic.address);

    // ========= PoolConfigurator logic =========
    // const PoolConfiguratorLogic = await ethers.getContractFactory(`PoolConfigurator`);
    // const poolConfiguratorLogic = await PoolConfiguratorLogic.deploy();
    // await poolConfiguratorLogic.deployed();

    // console.log(`${networkName.toUpperCase()}_POOL_CONFIGURATOR_LOGIC address: `, poolConfiguratorLogic.address);
    // writeToEnvFile(`${networkName.toUpperCase()}_POOL_CONFIGURATOR_LOGIC`, poolConfiguratorLogic.address);

    // ========= TToken logic =========
    // const TToken = await ethers.getContractFactory(`TToken`);
    // const tToken = await TToken.deploy();
    // await tToken.deployed();

    // console.log(`${networkName.toUpperCase()}_T_TOKEN_LOGIC address: `, tToken.address);
    // writeToEnvFile(`${networkName.toUpperCase()}_T_TOKEN_LOGIC`, tToken.address);

    // ========= VariableDebtToken logic =========
    // const VariableDebtTokenLogic = await ethers.getContractFactory(`VariableDebtToken`);
    // const variableDebtTokenLogic = await VariableDebtTokenLogic.deploy();
    // await variableDebtTokenLogic.deployed();

    // console.log(`${networkName.toUpperCase()}_VARIABLE_DEBT_TOKEN_LOGIC address: `, variableDebtTokenLogic.address);
    // writeToEnvFile(`${networkName.toUpperCase()}_VARIABLE_DEBT_TOKEN_LOGIC`, variableDebtTokenLogic.address);

    // console.log('\n');

    // ========= Deploy pool proxy =========
    console.log(`========= Deploy pool proxy =========`);

    // ========= init pool proxy =========
    console.log('========= init pool proxy =========');

    // const dataInitPool = encode('initPool(address,address)', [
    //     lendingPoolLogic.address,
    //     poolConfiguratorLogic.address
    // ]);

    // await execute(multiSigWallet.address, addressesProvider.address, dataInitPool);
    // console.log("addresses", dataInitPool);

    // ========= Pool proxy =========
    const poolProxyAddress = await addressesProvider.getPool();
    console.log(`${networkName.toUpperCase()}_POOL_PROXY address: `, poolProxyAddress);
    writeToEnvFile(`${networkName.toUpperCase()}_POOL_PROXY`, poolProxyAddress);

    // ========= PoolConfigurator proxy =========
    const poolConfiguratorProxyAddress = await addressesProvider.getPoolConfigurator();
    console.log(`${networkName.toUpperCase()}_POOL_CONFIGURATOR_PROXY address: `, poolConfiguratorProxyAddress);
    writeToEnvFile(`${networkName.toUpperCase()}_POOL_CONFIGURATOR_PROXY`, poolConfiguratorProxyAddress);

    console.log('\n');
}

async function main() {
    await deploy();
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/lending/00-deploy-pool/03-deploy-pool.ts --network bsc_testnet
// npx hardhat run scripts/lending/00-deploy-pool/03-deploy-pool.ts --network base_mainnet
// npx hardhat run scripts/lending/00-deploy-pool/03-deploy-pool.ts --network arbitrum_one_mainnet
// npx hardhat run scripts/lending/00-deploy-pool/03-deploy-pool.ts --network bsc_mainnet