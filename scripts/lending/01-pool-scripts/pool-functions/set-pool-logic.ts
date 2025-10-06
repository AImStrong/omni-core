import { ethers, network } from 'hardhat';
import { writeToEnvFile } from '../../../utils/helper';
import { execute } from '../../../utils/multisig';
import { encode } from '../../../utils/encode';
import * as dotenv from 'dotenv';
dotenv.config();

async function setPoolImpl(newAddress: string | undefined | null) {
    let networkName = network.name;
    const multiSigWallet = await ethers.getContractAt(`MultiSigWallet`, process.env[`${networkName.toUpperCase()}_MULTISIG_WALLET`]!);
    const addressesProvider = await ethers.getContractAt(`contracts/lending-protocol/factory/AddressesProvider.sol:AddressesProvider`, process.env[`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_PROXY`]!);

    // ========= setPoolImpl =========
    console.log(`========= setPoolImpl =========`);

    if (!newAddress) {
        const LendingPoolLogic = await ethers.getContractFactory("Pool", {
            libraries: {
                SupplyLogic:      process.env[`${networkName.toUpperCase()}_SUPPLY_LOGIC`]!,
                BorrowLogic:      process.env[`${networkName.toUpperCase()}_BORROW_LOGIC`]!,
                LiquidationLogic: process.env[`${networkName.toUpperCase()}_LIQUIDATION_LOGIC`]!,
                PoolLogic:        process.env[`${networkName.toUpperCase()}_POOL_LOGIC`]!,
                // MoveAssetsLogic:  process.env[`${networkName.toUpperCase()}_MOVE_ASSETS_LOGIC`]!
            }
        });
        const lendingPoolLogic = await LendingPoolLogic.deploy();
        await lendingPoolLogic.deployed();

        console.log(`${networkName.toUpperCase()}_LENDING_POOL_LOGIC address: `, lendingPoolLogic.address);
        writeToEnvFile(`${networkName.toUpperCase()}_LENDING_POOL_LOGIC`, lendingPoolLogic.address);

        newAddress = lendingPoolLogic.address;
    }

    const dataSetId = encode("setPoolImpl(address)", [newAddress]);
    console.log(dataSetId);
    // await execute(multiSigWallet.address, addressesProvider.address, dataSetId);

    console.log('pool proxy: ', await addressesProvider.getPool());
}

async function setPoolConfiguratorImpl(newAddress: string | undefined | null) {
    let networkName = network.name;
    const multiSigWallet = await ethers.getContractAt(`MultiSigWallet`, process.env[`${networkName.toUpperCase()}_MULTISIG_WALLET`]!);
    const addressesProvider = await ethers.getContractAt(`contracts/lending-protocol/factory/AddressesProvider.sol:AddressesProvider`, process.env[`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_PROXY`]!);

    // ========= setPoolConfiguratorImpl =========
    console.log(`========= setPoolConfiguratorImpl =========`);

    if (!newAddress) {
        const PoolConfiguratorLogic = await ethers.getContractFactory("PoolConfigurator");
        const poolConfiguratorLogic = await PoolConfiguratorLogic.deploy();
        await poolConfiguratorLogic.deployed();

        console.log(`${networkName.toUpperCase()}_POOL_CONFIGURATOR_LOGIC address: `, poolConfiguratorLogic.address);
        writeToEnvFile(`${networkName.toUpperCase()}_POOL_CONFIGURATOR_LOGIC`, poolConfiguratorLogic.address);

        newAddress = poolConfiguratorLogic.address;
    }

    const dataSetId = encode("setPoolConfiguratorImpl(address)", [newAddress]);
    // await execute(multiSigWallet.address, addressesProvider.address, dataSetId);

    console.log(dataSetId);
    
    console.log('pool configurator proxy: ', await addressesProvider.getPoolConfigurator());
}

export {
    setPoolImpl,
    setPoolConfiguratorImpl
}