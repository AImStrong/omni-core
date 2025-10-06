import { ethers, network } from 'hardhat';
import { execute } from '../../../utils/multisig';
import { encode } from '../../../utils/encode';
import { writeToEnvFile } from '../../../utils/helper';
import * as dotenv from 'dotenv';
dotenv.config();

async function updateAddressesProviderImpl(newAddress: string | null | undefined) {
    let networkName = network.name;

    // ========= Contracts required =========
    const multiSigWallet = await ethers.getContractAt(`MultiSigWallet`, process.env[`${networkName.toUpperCase()}_MULTISIG_WALLET`]!);
    const factoryRegistry = await ethers.getContractAt(`contracts/controller-protocol/configuration/FactoryRegistry.sol:FactoryRegistry`, process.env[`${networkName.toUpperCase()}_FACTORY_REGISTRY`]!);

    // ========= Update AddressesProvider Implementation =========
    console.log('========= Updating AddressesProvider Implementation =========');

    if (!newAddress) {
        const AddressesProviderLogic = await ethers.getContractFactory("contracts/controller-protocol/configuration/AddressesProvider.sol:AddressesProvider");
        const addressesProviderLogic = await AddressesProviderLogic.deploy();
        await addressesProviderLogic.deployed();

        console.log(`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_LOGIC address: `, addressesProviderLogic.address);
        writeToEnvFile(`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_LOGIC`, addressesProviderLogic.address);

        newAddress = addressesProviderLogic.address;
    }

    // For AddressesProvider, we call setAddressesProviderImpl through FactoryRegistry
    const data = encode('setAddressesProviderImpl(address)', [newAddress]);
    await execute(multiSigWallet.address, factoryRegistry.address, data);

    console.log('AddressesProvider proxy address: ', await factoryRegistry.getAddressesProvider());
    console.log('========= AddressesProvider Implementation Updated =========');
}

export {
    updateAddressesProviderImpl
} 