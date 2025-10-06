import { updateControllerImpl } from './controller-functions/update-controller-impl';
import { ethers, network } from 'hardhat';
import * as dotenv from 'dotenv';
dotenv.config();

const config = {
    // Set to null to deploy new implementation, or provide the address of an existing implementation
    newControllerImpl: null
}

async function main() {
    const networkName = network.name;

    const controller = await ethers.getContractAt(`CrossChainLendingController`, process.env[`${networkName.toUpperCase()}_CONTROLLER_PROXY`]!);
    console.log('current controller revision: ', await controller.CONTROLLER_REVISION());

    // await updateControllerImpl(config.newControllerImpl);

    console.log('new controller revision: ', await controller.CONTROLLER_REVISION());
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/controller/01-controller-scripts/update-controller-impl.ts --network zeta_testnet
// npx hardhat run scripts/controller/01-controller-scripts/update-controller-impl.ts --network zeta_mainnet