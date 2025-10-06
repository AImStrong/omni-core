import { ethers, network } from 'hardhat';
import { execute } from '../../../utils/multisig';
import { encode } from '../../../utils/encode';
import { writeToEnvFile } from '../../../utils/helper';
import * as dotenv from 'dotenv';
dotenv.config();

async function updateConfiguratorImpl(newAddress: string | null | undefined) {
    let networkName = network.name;

    // ========= Contracts required =========
    const multiSigWallet = await ethers.getContractAt(`MultiSigWallet`, process.env[`${networkName.toUpperCase()}_MULTISIG_WALLET`]!);
    const addressesProvider = await ethers.getContractAt(`contracts/controller-protocol/configuration/AddressesProvider.sol:AddressesProvider`, process.env[`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_PROXY`]!);

    // ========= Update ControllerConfigurator Implementation =========
    console.log('========= Updating ControllerConfigurator Implementation =========');

    if (!newAddress) {
        const ControllerConfiguratorLogic = await ethers.getContractFactory("CrossChainLendingControllerConfigurator");
        const controllerConfiguratorLogic = await ControllerConfiguratorLogic.deploy();
        await controllerConfiguratorLogic.deployed();

        console.log(`${networkName.toUpperCase()}_CONTROLLER_CONFIGURATOR_LOGIC address: `, controllerConfiguratorLogic.address);
        writeToEnvFile(`${networkName.toUpperCase()}_CONTROLLER_CONFIGURATOR_LOGIC`, controllerConfiguratorLogic.address);

        newAddress = controllerConfiguratorLogic.address;
    }

    const data = encode('setControllerConfiguratorImpl(address)', [newAddress]);
    await execute(multiSigWallet.address, addressesProvider.address, data);

    console.log('ControllerConfigurator proxy address: ', await addressesProvider.getControllerConfigurator());
    console.log('========= ControllerConfigurator Implementation Updated =========');
}

export {
    updateConfiguratorImpl
} 