import { getControllerInfo } from './controller-functions/get-controller-info';
import { ethers, network } from 'hardhat';
import * as dotenv from 'dotenv';
dotenv.config();

async function main() {
    await getControllerInfo();
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/controller/01-controller-scripts/get-controller-info.ts --network zeta_testnet
// npx hardhat run scripts/controller/01-controller-scripts/get-controller-info.ts --network zeta_mainnet