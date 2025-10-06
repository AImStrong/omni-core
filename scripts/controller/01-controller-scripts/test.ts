import { ethers, network } from 'hardhat';
import * as dotenv from 'dotenv';
dotenv.config();

async function main() {
    const networkName = network.name;
    const controller = await ethers.getContractAt("CrossChainLendingController", process.env[`${networkName.toUpperCase()}_CONTROLLER_PROXY`]!);
    const universal = await ethers.getContractAt("UniversalMessenger", process.env[`${networkName.toUpperCase()}_UNIVERSAL_MESSENGER_PROXY`]!);

    const oracle = await ethers.getContractAt("TravaOracle", process.env[`${networkName.toUpperCase()}_PRICE_ORACLE`]!);
    console.log(await oracle.getAssetPrice("0x82aF49447D8a07e3bd95BD0d56f35241523fBab1"));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/controller/01-controller-scripts/test.ts --network zeta_testnet
// npx hardhat run scripts/controller/01-controller-scripts/test.ts --network zeta_mainnet