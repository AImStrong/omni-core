import { ethers, network } from 'hardhat';
import { writeToEnvFile } from '../../utils/helper';
import { execute } from '../../utils/multisig';
import { encode } from '../../utils/encode';
import * as dotenv from 'dotenv';
dotenv.config();

async function deploy() {
    let networkName = network.name;
    const multiSigWallet = await ethers.getContractAt(`MultiSigWallet`, process.env[`${networkName.toUpperCase()}_MULTISIG_WALLET`]!);

    // ========= Deploy factory =========
    console.log(`========= Deploy factory =========`);

    // ========= AddressesProvider logic =========
    const AddressesProviderLogic = await ethers.getContractFactory("contracts/controller-protocol/configuration/AddressesProvider.sol:AddressesProvider");
    const addressesProviderLogic = await AddressesProviderLogic.deploy();
    await addressesProviderLogic.deployed();
 
    console.log(`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_LOGIC address: `, addressesProviderLogic.address);
    writeToEnvFile(`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_LOGIC`, addressesProviderLogic.address);

    // ========= FactoryRegistry =========

    const FactoryRegistry = await ethers.getContractFactory("contracts/controller-protocol/configuration/FactoryRegistry.sol:FactoryRegistry");
    const factoryRegistry = await FactoryRegistry.deploy(multiSigWallet.address);
    await factoryRegistry.deployed();

    console.log(`${networkName.toUpperCase()}_FACTORY_REGISTRY address: `, factoryRegistry.address);
    writeToEnvFile(`${networkName.toUpperCase()}_FACTORY_REGISTRY`, factoryRegistry.address);

    console.log('\n');

    // ========= Config FactoryRegistry =========
    console.log('========= Config FactoryRegistry =========');

    // ========= setInterestRateFactoryImpl =========
    console.log(`========= setInterestRateFactoryImpl =========`);

    const dataSetAddressesProvider = encode(`setAddressesProviderImpl(address)`, [addressesProviderLogic.address]);
    await execute(multiSigWallet.address, factoryRegistry.address, dataSetAddressesProvider);

    // ========= AddressesProviderFactory proxy =========
    const addressesProviderProxyAddress = await factoryRegistry.getAddressesProvider();
    console.log(`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_PROXY address: `, addressesProviderProxyAddress);
    writeToEnvFile(`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_PROXY`, addressesProviderProxyAddress);

    console.log('\n');

    // ========= config AddressesProvider proxy =========
    console.log("========= config AddressesProvider proxy =========");

    // ========= AddressProvider proxy =========
    const addressesProviderProxy = await ethers.getContractAt("contracts/controller-protocol/configuration/AddressesProvider.sol:AddressesProvider", addressesProviderProxyAddress);

    // ========= setGovernance =========
    const setGovernance = await addressesProviderProxy.setGovernance(multiSigWallet.address);
    await setGovernance.wait();
    console.log("setGovernance hash: ", setGovernance.hash);
    console.log("AddressesProvider.getGovernance: ", await addressesProviderProxy.getGovernance());
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

// npx hardhat run scripts/controller/00-deploy-controller/01-deploy-factory.ts --network zeta_testnet