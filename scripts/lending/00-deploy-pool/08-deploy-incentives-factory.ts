import { ethers, network } from 'hardhat';
import { writeToEnvFile } from '../../utils/helper';
import { encode } from '../../utils/encode';
import * as dotenv from 'dotenv';
dotenv.config();

async function deploy() {
    let networkName = network.name;
    const addressesProvider = await ethers.getContractAt(`contracts/lending-protocol/factory/AddressesProvider.sol:AddressesProvider`, process.env[`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_PROXY`]!);

    // const Incentives = await ethers.getContractFactory(`IncentivesFactory`);
    // const incentives = await Incentives.deploy("0x81ff99181d4Bdd14f64dC1a0e1A98EF81688bA0a");
    // await incentives.deployed();

    // console.log(incentives.address);
    // console.log(await incentives.getGovernance());

    // console.log(`${networkName.toUpperCase()}_INCENTIVES_FACTORY address: `, incentives.address);
    // writeToEnvFile(`${networkName.toUpperCase()}_INCENTIVES_FACTORY`, incentives.address);

    // const data = encode("setAddress(bytes32,address)", [
    //     ethers.utils.formatBytes32String("INCENTIVES_FACTORY"),
    //     process.env[`${networkName.toUpperCase()}_INCENTIVES_FACTORY`]!
    // ]);
    // console.log(data);

    console.log("AddressesProvider.getIncentivesFactory()", await addressesProvider.getAddress(ethers.utils.formatBytes32String("INCENTIVES_FACTORY")));
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

// npx hardhat run scripts/lending/00-deploy-pool/08-deploy-incentives-factory.ts --network bsc_testnet
// npx hardhat run scripts/lending/00-deploy-pool/08-deploy-incentives-factory.ts --network base_mainnet
// npx hardhat run scripts/lending/00-deploy-pool/08-deploy-incentives-factory.ts --network arbitrum_one_mainnet
// npx hardhat run scripts/lending/00-deploy-pool/08-deploy-incentives-factory.ts --network bsc_mainnet