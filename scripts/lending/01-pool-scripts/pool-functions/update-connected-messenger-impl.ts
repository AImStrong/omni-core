import { ethers, network } from 'hardhat';
import { writeToEnvFile } from '../../../utils/helper';
import { execute } from '../../../utils/multisig';
import { encode } from '../../../utils/encode';
import * as dotenv from 'dotenv';
dotenv.config();

async function updateConnectedMessengerImpl(newAddress?: string) {
    let networkName = network.name;
    const multiSigWallet = await ethers.getContractAt(`MultiSigWallet`, process.env[`${networkName.toUpperCase()}_MULTISIG_WALLET`]!);
    const factoryRegistry = await ethers.getContractAt(`contracts/lending-protocol/factory/FactoryRegistry.sol:FactoryRegistry`, process.env[`${networkName.toUpperCase()}_FACTORY_REGISTRY`]!);

    // ========= Update ConnectedMessenger Implementation =========
    console.log(`========= Update ConnectedMessenger Implementation =========`);

    if (!newAddress) {
        // Deploy new implementation
        const ConnectedMessengerLogic = await ethers.getContractFactory(`contracts/lending-protocol/message-sender/ConnectedMessenger.sol:ConnectedMessenger`);
        const connectedMessengerLogic = await ConnectedMessengerLogic.deploy();
        await connectedMessengerLogic.deployed();

        console.log(`${networkName.toUpperCase()}_CONNECTED_MESSENGER_LOGIC address: `, connectedMessengerLogic.address);
        writeToEnvFile(`${networkName.toUpperCase()}_CONNECTED_MESSENGER_LOGIC`, connectedMessengerLogic.address);

        newAddress = connectedMessengerLogic.address;
    }

    // Update implementation
    const dataSetConnectedMessengerImpl = encode(`setConnectedMessengerImpl(address,address)`, [
        newAddress,
        multiSigWallet.address
    ]);
    await execute(multiSigWallet.address, factoryRegistry.address, dataSetConnectedMessengerImpl);

    // Get updated address
    const connectedMessengerAddress = await factoryRegistry.getConnectedMessenger();
    console.log(`ConnectedMessenger address: ${connectedMessengerAddress}`);

    return newAddress;
}

export {
    updateConnectedMessengerImpl
} 