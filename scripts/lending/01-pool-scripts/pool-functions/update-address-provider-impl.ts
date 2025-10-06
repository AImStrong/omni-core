import { ethers, network } from 'hardhat';
import { writeToEnvFile } from '../../../utils/helper';
import { execute } from '../../../utils/multisig';
import { encode } from '../../../utils/encode';
import * as dotenv from 'dotenv';
dotenv.config();

async function updateAddressProviderImpl(newAddress?: string) {
    let networkName = network.name;
    const multiSigWallet = await ethers.getContractAt(`MultiSigWallet`, process.env[`${networkName.toUpperCase()}_MULTISIG_WALLET`]!);
    const factoryRegistry = await ethers.getContractAt(`contracts/lending-protocol/factory/FactoryRegistry.sol:FactoryRegistry`, process.env[`${networkName.toUpperCase()}_FACTORY_REGISTRY`]!);

    // ========= Update AddressesProvider Implementation =========
    console.log(`========= Update AddressesProvider Implementation =========`);

    if (!newAddress) {
        // Deploy new implementation
        const AddressesProviderLogic = await ethers.getContractFactory(`contracts/lending-protocol/factory/AddressesProvider.sol:AddressesProvider`);
        const addressesProviderLogic = await AddressesProviderLogic.deploy();
        await addressesProviderLogic.deployed();

        console.log(`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_LOGIC address: `, addressesProviderLogic.address);
        writeToEnvFile(`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_LOGIC`, addressesProviderLogic.address);

        newAddress = addressesProviderLogic.address;
    }

    // Update implementation
    const dataSetAddressesProvider = encode(`setAddressesProviderImpl(address)`, [newAddress]);
    await execute(multiSigWallet.address, factoryRegistry.address, dataSetAddressesProvider);

    // Get updated address
    const addressesProviderAddress = await factoryRegistry.getAddressesProvider();
    console.log(`AddressesProvider address: ${addressesProviderAddress}`);

    return newAddress;
}

export {
    updateAddressProviderImpl
} 