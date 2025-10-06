import { ethers, network } from 'hardhat';
import { writeToEnvFile } from '../../utils/helper';
import { encode } from '../../utils/encode';
import * as dotenv from 'dotenv';
dotenv.config();

const config = {
    spender: [
        "0x5943b07E46511B13b0FB167A2a93a8D8dFfB958A",
        "0x3Fff357de53C7A08D8002298b7b14818959Ba36B",
        "0x05cC1d98bCe5CB60c9c4aD4c6dEA89Ef11fE28F4"
    ],
    asset: [
        "0x55d398326f99059fF775485246999027B3197955",
        "0x55d398326f99059fF775485246999027B3197955",
        "0x55d398326f99059fF775485246999027B3197955"
    ]
}

async function deploy() {
    let networkName = network.name;
    
    // const Funder = await ethers.getContractFactory("Funder");
    // const funder = await Funder.deploy();
    // await funder.deployed();

    // console.log(`${networkName.toUpperCase()}_FUNDER address: `, funder.address);
    // writeToEnvFile(`${networkName.toUpperCase()}_FUNDER`, funder.address);

    const funder = await ethers.getContractAt("Funder", process.env[`${networkName.toUpperCase()}_FUNDER`]!);

    // const tx = await funder.approveMaxBatch(config.spender, config.asset);
    // await tx.wait();

    // console.log("approve hash: ", tx.hash);

    // for (let i = 0; i < config.asset.length; i++) {
    //     const token = await ethers.getContractAt("BEP20", config.asset[i]);
    //     console.log(await token.allowance(funder.address, config.spender[i]));
    // }

    // const transferOwner = await funder.transferOwnership("0x81ff99181d4Bdd14f64dC1a0e1A98EF81688bA0a");
    // await transferOwner.wait();
    // console.log("transfer ownership tx hash: ", transferOwner.hash);
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