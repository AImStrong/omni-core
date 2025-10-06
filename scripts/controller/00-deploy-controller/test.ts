import { ethers, network } from 'hardhat';
import { writeToEnvFile } from '../../utils/helper';
import * as dotenv from 'dotenv';
dotenv.config();

async function deploy() {
    let networkName = network.name;
    const addressesProvider = await ethers.getContractAt("contracts/controller-protocol/configuration/AddressesProvider.sol:AddressesProvider", process.env[`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_PROXY`]!);

    // console.log("Pool update controller: ", await addressesProvider.getPoolUpdateController());
    // console.log("pool: ", await addressesProvider.getPool());
    // console.log("pool config: ", await addressesProvider.getPoolConfigurator());
    // console.log("pool owner: ", await addressesProvider.getPoolOwner());
    // console.log("governance: ", await addressesProvider.getGovernance());
    // console.log("connected messenger: ", await addressesProvider.getConnectedMessenger());
    // console.log("universal messenger: ", await addressesProvider.getUniversalMessenger())

    const messenger = await ethers.getContractAt("ConnectedMessenger", process.env[`${networkName.toUpperCase()}_CONNECTED_MESSENGER_PROXY`]!);

    console.log("gateway: ", await messenger.gateway());
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

// npx hardhat run scripts/controller/00-deploy-controller/test.ts --network bsc_testnet