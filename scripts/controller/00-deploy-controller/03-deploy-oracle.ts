import { ethers, network } from 'hardhat';
import { writeToEnvFile } from '../../utils/helper';
import * as dotenv from 'dotenv';
dotenv.config();

async function deploy() {
    const networkName = network.name;

    // const GetPyth = await ethers.getContractFactory("MockOracle");

    // // var getPyth = await GetPyth.deploy(process.env[`${networkName.toUpperCase()}_PRICE_ORACLE_ADDRESS`]!);
    // var getPyth = await GetPyth.deploy();
    // await getPyth.deployed();

    // console.log(`${networkName.toUpperCase()}_PRICE_ORACLE address: `, getPyth.address);
    // writeToEnvFile(`${networkName.toUpperCase()}_PRICE_ORACLE`, getPyth.address);

    const PriceOracle = await ethers.getContractFactory("TravaOracle");
    var priceOracle = await PriceOracle.deploy(process.env[`${networkName.toUpperCase()}_PYTH_ADDRESS`]!, 60);
    await priceOracle.deployed();

    console.log(`${networkName.toUpperCase()}_PRICE_ORACLE address: `, priceOracle.address);
    writeToEnvFile(`${networkName.toUpperCase()}_PRICE_ORACLE`, priceOracle.address);
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

// npx hardhat run scripts/controller/00-deploy-controller/03-deploy-oracle.ts --network zeta_testnet