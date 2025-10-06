import { ethers, network } from 'hardhat';
import { writeToEnvFile } from '../../utils/helper';
import { encode } from '../../utils/encode';
import * as dotenv from 'dotenv';
dotenv.config();

const governance = "0x81ff99181d4Bdd14f64dC1a0e1A98EF81688bA0a";

async function deploy(numRequired: number) {
    let networkName = network.name;

    // ========= Deploy factory =========
    console.log(`========= Deploy factory =========`);

    // ========= AddressesProvider logic =========
    // const AddressesProviderLogic = await ethers.getContractFactory(`contracts/lending-protocol/factory/AddressesProvider.sol:AddressesProvider`);
    // const addressesProviderLogic = await AddressesProviderLogic.deploy();
    // await addressesProviderLogic.deployed();

    // console.log(`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_LOGIC address: `, addressesProviderLogic.address);
    // writeToEnvFile(`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_LOGIC`, addressesProviderLogic.address);

    // ========= InterestRateFactory logic =========
    // const InterestRateFactoryLogic = await ethers.getContractFactory(`InterestRateFactory`);
    // const interestRateFactoryLogic = await InterestRateFactoryLogic.deploy();
    // await interestRateFactoryLogic.deployed();

    // console.log(`${networkName.toUpperCase()}_INTEREST_RATE_FACTORY_LOGIC address: `, interestRateFactoryLogic.address);
    // writeToEnvFile(`${networkName.toUpperCase()}_INTEREST_RATE_FACTORY_LOGIC`, interestRateFactoryLogic.address);
    
    // ========= FactoryRegistry =========
    // const FactoryRegistry = await ethers.getContractFactory(`contracts/lending-protocol/factory/FactoryRegistry.sol:FactoryRegistry`);
    // const factoryRegistry = await FactoryRegistry.deploy(governance);
    // await factoryRegistry.deployed();

    // console.log(`${networkName.toUpperCase()}_FACTORY_REGISTRY address: `, factoryRegistry.address);
    // writeToEnvFile(`${networkName.toUpperCase()}_FACTORY_REGISTRY`, factoryRegistry.address);

    // console.log('\n');

    // ========= Config FactoryRegistry =========
    // console.log('========= Config FactoryRegistry =========');

    // ========= setInterestRateFactoryImpl =========
    // console.log(`========= setInterestRateFactoryImpl =========`);
    // const dataSetInterestRate = encode(`setInterestRateFactoryImpl(address)`, [interestRateFactoryLogic.address]);
    // await execute(multiSigWallet.address, factoryRegistry.address, dataSetInterestRate);
    // console.log("factory", dataSetInterestRate);

    // ========= setAddressesProviderImpl =========
    // console.log(`========= setAddressesProviderImpl =========`);
    // const dataSetAddressesProvider = encode(`setAddressesProviderImpl(address)`, [addressesProviderLogic.address]);
    // await execute(multiSigWallet.address, factoryRegistry.address, dataSetAddressesProvider);
    // console.log("factory", dataSetAddressesProvider);

    const factoryRegistry = await ethers.getContractAt(`contracts/lending-protocol/factory/FactoryRegistry.sol:FactoryRegistry`, "0xc0Bc1Cc8856D6FFd988179E5c10ffF9f0a15C5B3");

    // ========= InterestRateFactory proxy =========
    const interestRateFactoryProxyAddress = await factoryRegistry.getInterestRateFactory();
    console.log(`${networkName.toUpperCase()}_INTEREST_RATE_FACTORY_PROXY address: `, interestRateFactoryProxyAddress);
    writeToEnvFile(`${networkName.toUpperCase()}_INTEREST_RATE_FACTORY_PROXY`, interestRateFactoryProxyAddress);

    // ========= AddressesProvider proxy =========
    const addressesProviderProxyAddress = await factoryRegistry.getAddressesProvider();
    console.log(`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_PROXY address: `, addressesProviderProxyAddress);
    writeToEnvFile(`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_PROXY`, addressesProviderProxyAddress);

    console.log('\n');

    // ========= config AddressesProvider proxy =========
    console.log(`========= config AddressesProvider proxy =========`);

    // ========= AddressesProvider proxy =========
    const addressesProviderProxy = await ethers.getContractAt(`contracts/lending-protocol/factory/AddressesProvider.sol:AddressesProvider`, addressesProviderProxyAddress);

    // ========= set Governance ========= 
    const setGovernance = await addressesProviderProxy.setGovernance(governance);
    await setGovernance.wait();
    console.log(`setGovernance hash: `, setGovernance.hash);

    const getGovernance = await addressesProviderProxy.getGovernance();
    console.log(`AddressesProvider.getGovernance: `, getGovernance);

    console.log('\n');
}

async function main() {
    await deploy(1);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/lending/00-deploy-pool/01-deploy-factory.ts --network bsc_testnet
// npx hardhat run scripts/lending/00-deploy-pool/01-deploy-factory.ts --network base_mainnet
// npx hardhat run scripts/lending/00-deploy-pool/01-deploy-factory.ts --network arbitrum_one_mainnet
// npx hardhat run scripts/lending/00-deploy-pool/01-deploy-factory.ts --network bsc_mainnet