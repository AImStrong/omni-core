import { ethers, network } from 'hardhat';
import { writeToEnvFile } from '../../utils/helper';
import { execute } from '../../utils/multisig';
import { encode } from '../../utils/encode';
import * as dotenv from 'dotenv';
dotenv.config();

async function deploy() {
    let networkName = network.name;
    let data;
    const multiSigWallet = await ethers.getContractAt(`MultiSigWallet`, process.env[`${networkName.toUpperCase()}_MULTISIG_WALLET`]!);
    const factoryRegistry = await ethers.getContractAt(`contracts/controller-protocol/configuration/FactoryRegistry.sol:FactoryRegistry`, process.env[`${networkName.toUpperCase()}_FACTORY_REGISTRY`]!);

    // ========= deploy UniversalMessenger logic =========
    console.log('========= deploy UniversalMessenger logic =========');

    // ========= UniversalMessenger logic =========
    const UniversalMessengerLogic = await ethers.getContractFactory(`UniversalMessenger`);
    const universalMessengerLogic = await UniversalMessengerLogic.deploy();
    await universalMessengerLogic.deployed();
    
    console.log(`${networkName.toUpperCase()}_UNIVERSAL_MESSENGER_LOGIC address: `, universalMessengerLogic.address);
    writeToEnvFile(`${networkName.toUpperCase()}_UNIVERSAL_MESSENGER_LOGIC`, universalMessengerLogic.address);

    // ========= deploy UniversalMessenger proxy =========
    console.log('========= deploy UniversalMessenger proxy =========');

    data = encode('setUniversalMessengerImpl(address)', [
        universalMessengerLogic.address
    ]);
    await execute(multiSigWallet.address, factoryRegistry.address, data)

    const universalMessengerProxyAddress = await factoryRegistry.getUniversalMessenger();
    console.log(`${networkName.toUpperCase()}_UNIVERSAL_MESSENGER_PROXY address: `, universalMessengerProxyAddress);
    writeToEnvFile(`${networkName.toUpperCase()}_UNIVERSAL_MESSENGER_PROXY`, universalMessengerProxyAddress);

    const universalMessengerProxy = await ethers.getContractAt('UniversalMessenger', universalMessengerProxyAddress);

    // ========= setUniversalMessenger for AddressesProvider =========
    console.log('========= setUniversalMessenger for AddressesProvider =========');

    const addressesProviderProxy = await ethers.getContractAt(`contracts/controller-protocol/configuration/AddressesProvider.sol:AddressesProvider`, process.env[`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_PROXY`]!);
    data = encode('setUniversalMessenger(address)', [universalMessengerProxyAddress]);
    await execute(multiSigWallet.address, addressesProviderProxy.address, data);

    console.log('UniversalMessenger in AddressesProvider: ', await addressesProviderProxy.getUniversalMessenger());
    
    // ========= setGasLimit =========
    console.log('========= setGasLimit =========');

    data = encode('setGasLimit(uint256)', [500000]); // subject to change
    await execute(multiSigWallet.address, universalMessengerProxy.address, data);

    console.log('gasLimit: ', await universalMessengerProxy.gasLimit());

    // ========= setGateway =========
    console.log('========= setGateway =========');

    data = encode('setGateway(address)', [process.env[`${networkName.toUpperCase()}_GATEWAY`]!]);
    await execute(multiSigWallet.address, universalMessengerProxy.address, data);

    console.log('gateway: ', await universalMessengerProxy.gateway());

    // ========= setAddressesProvider =========
    console.log('========= setAddressesProvider =========');

    data = encode('setAddressesProvider(address)', [process.env[`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_PROXY`]!]);
    await execute(multiSigWallet.address, universalMessengerProxy.address, data);

    console.log('addressesProvider: ', await universalMessengerProxy.addressesProvider());

    // ========= setController =========
    console.log('========= setController =========');

    data = encode('setController(address)', [process.env[`${networkName.toUpperCase()}_CONTROLLER_PROXY`]!]);
    await execute(multiSigWallet.address, universalMessengerProxy.address, data);

    console.log('controller: ', await universalMessengerProxy.controller());

    // ========= setSystemContract =========
    console.log('========= setSystemContract =========');

    data = encode('setSystemContract(address)', [process.env[`${networkName.toUpperCase()}_SYSTEM_CONTRACT`]!]);
    await execute(multiSigWallet.address, universalMessengerProxy.address, data);

    console.log('SystemContract: ', await universalMessengerProxy.systemContract());
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

// npx hardhat run scripts/controller/00-deploy-controller/05-deploy-messenger.ts --network zeta_testnet