import { ethers, network } from 'hardhat';
import { writeToEnvFile } from '../../utils/helper';
import { encode } from '../../utils/encode';
import * as dotenv from 'dotenv';
dotenv.config();

const governance = "0x81ff99181d4Bdd14f64dC1a0e1A98EF81688bA0a";

async function deploy() {
    let networkName = network.name;
    const factoryRegistry = await ethers.getContractAt(`contracts/lending-protocol/factory/FactoryRegistry.sol:FactoryRegistry`, process.env[`${networkName.toUpperCase()}_FACTORY_REGISTRY`]!);

    // ========= deploy message sender logic =========
    console.log('========= deploy message sender logic =========');

    // ========= ConnectedMessenger logic =========
    // const ConnectedMessengerLogic = await ethers.getContractFactory(`ConnectedMessenger`);
    // const connectedMessengerLogic = await ConnectedMessengerLogic.deploy();
    // await connectedMessengerLogic.deployed();
    
    // console.log(`${networkName.toUpperCase()}_CONNECTED_MESSENGER_LOGIC address: `, connectedMessengerLogic.address);
    // writeToEnvFile(`${networkName.toUpperCase()}_CONNECTED_MESSENGER_LOGIC`, connectedMessengerLogic.address);

    // console.log('\n');

    // ========= deploy message sender proxy =========
    // console.log('========= deploy message sender proxy =========');

    // ========= ConnectedMessenger proxy =========
    // console.log('========= ConnectedMessenger proxy =========');

    // let data = encode('setConnectedMessengerImpl(address,address)', [
    //     process.env[`${networkName.toUpperCase()}_CONNECTED_MESSENGER_LOGIC`]!,
    //     governance
    // ]);
    // console.log("factory", data);

    // await execute(multiSigWallet.address, factoryRegistry.address, data);

    const connectedMessengerProxyAddress = await factoryRegistry.getConnectedMessenger();
    // console.log(`${networkName.toUpperCase()}_CONNECTED_MESSENGER_PROXY address: `, connectedMessengerProxyAddress);
    // writeToEnvFile(`${networkName.toUpperCase()}_CONNECTED_MESSENGER_PROXY`, connectedMessengerProxyAddress);

    const connectedMessengerProxy = await ethers.getContractAt('ConnectedMessenger', connectedMessengerProxyAddress);

    // ========= setMinGasValue =========
    // console.log('========= setMinGasValue =========');

    // data = encode('setMinGasValue(uint256)', [ethers.utils.parseEther('0')]);
    // await execute(multiSigWallet.address, connectedMessengerProxy.address, data);

    // console.log('MinGasValue: ', await connectedMessengerProxy.MIN_GAS_VALUE());
    // console.log('\n');

    // ========= setGateway =========
    // console.log('========= setGateway =========');

    // let data = encode('setGateway(address)', [process.env[`${networkName.toUpperCase()}_GATEWAY`]!]);
    // await execute(multiSigWallet.address, connectedMessengerProxy.address, data);
    // console.log("msg", data);

    console.log('gateway: ', await connectedMessengerProxy.gateway());
    // console.log('\n');

    // ========= setAddressesProvider =========
    // console.log('========= setAddressesProvider =========');

    // data = encode('setAddressesProvider(address)', [process.env[`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_PROXY`]!]);
    // await execute(multiSigWallet.address, connectedMessengerProxy.address, data);
    // console.log("msg", data);

    console.log('addressesProvider: ', await connectedMessengerProxy.addressesProvider());
    // console.log('\n');
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

// npx hardhat run scripts/lending/00-deploy-pool/04-deploy-message-sender.ts --network bsc_testnet
// npx hardhat run scripts/lending/00-deploy-pool/04-deploy-message-sender.ts --network base_mainnet
// npx hardhat run scripts/lending/00-deploy-pool/04-deploy-message-sender.ts --network arbitrum_one_mainnet
// npx hardhat run scripts/lending/00-deploy-pool/04-deploy-message-sender.ts --network bsc_mainnet