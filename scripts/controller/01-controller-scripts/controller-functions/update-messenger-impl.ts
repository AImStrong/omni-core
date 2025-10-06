import { ethers, network } from 'hardhat';
import { execute } from '../../../utils/multisig';
import { encode } from '../../../utils/encode';
import { writeToEnvFile } from '../../../utils/helper';
import * as dotenv from 'dotenv';
dotenv.config();

async function updateMessengerImpl(newAddress: string | null | undefined) {
    let networkName = network.name;

    // ========= Contracts required =========
    const multiSigWallet = await ethers.getContractAt(`MultiSigWallet`, process.env[`${networkName.toUpperCase()}_MULTISIG_WALLET`]!);
    const factoryRegistry = await ethers.getContractAt(`contracts/controller-protocol/configuration/FactoryRegistry.sol:FactoryRegistry`, process.env[`${networkName.toUpperCase()}_FACTORY_REGISTRY`]!);

    // ========= Update UniversalMessenger Implementation =========
    console.log('========= Updating UniversalMessenger Implementation =========');

    if (!newAddress) {
        const UniversalMessengerLogic = await ethers.getContractFactory("UniversalMessenger");
        const universalMessengerLogic = await UniversalMessengerLogic.deploy();
        await universalMessengerLogic.deployed();

        console.log(`${networkName.toUpperCase()}_UNIVERSAL_MESSENGER_LOGIC address: `, universalMessengerLogic.address);
        writeToEnvFile(`${networkName.toUpperCase()}_UNIVERSAL_MESSENGER_LOGIC`, universalMessengerLogic.address);

        newAddress = universalMessengerLogic.address;
    }

    const data = encode('setUniversalMessengerImpl(address)', [newAddress]);
    await execute(multiSigWallet.address, factoryRegistry.address, data);

    console.log('UniversalMessenger proxy address: ', await factoryRegistry.getUniversalMessenger());
    console.log('========= UniversalMessenger Implementation Updated =========');
}

export {
    updateMessengerImpl
} 