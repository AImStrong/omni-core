import { addChainToController } from './controller-functions/add-chain';
import { ethers, network } from 'hardhat';
import * as dotenv from 'dotenv';
dotenv.config();

const config = {
    chainId: 56 // Change this to the desired chain ID
}

async function main() {
    await addChainToController(config.chainId);

    // let networkName = network.name;
    // const controller = await ethers.getContractAt("CrossChainLendingController", process.env[`${networkName.toUpperCase()}_CONTROLLER_PROXY`]!);

    // console.log(await controller.getChainsList());
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/controller/01-controller-scripts/add-chain.ts --network zeta_testnet
// npx hardhat run scripts/controller/01-controller-scripts/add-chain.ts --network zeta_mainnet