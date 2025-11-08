import { ethers, network } from 'hardhat';
import { writeToEnvFile } from '../../utils/helper';
import * as dotenv from 'dotenv';
dotenv.config();

async function deploy() {
    let networkName = network.name;
    
    const Funder = await ethers.getContractFactory("Funder");
    const funder = await Funder.deploy();
    await funder.deployed();

    console.log(`${networkName.toUpperCase()}_FUNDER address: `, funder.address);
    writeToEnvFile(`${networkName.toUpperCase()}_FUNDER`, funder.address);

    const transferOwner = await funder.transferOwnership("0x81ff99181d4Bdd14f64dC1a0e1A98EF81688bA0a");
    await transferOwner.wait();
    console.log("transfer ownership tx hash: ", transferOwner.hash);
    console.log(await funder.owner());
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

// npx hardhat run scripts/lending/00-deploy-pool/09-deploy-funder.ts --network bsc_testnet
// npx hardhat run scripts/lending/00-deploy-pool/09-deploy-funder.ts --network base_mainnet
// npx hardhat run scripts/lending/00-deploy-pool/09-deploy-funder.ts --network arbitrum_one_mainnet
// npx hardhat run scripts/lending/00-deploy-pool/09-deploy-funder.ts --network bsc_mainnet