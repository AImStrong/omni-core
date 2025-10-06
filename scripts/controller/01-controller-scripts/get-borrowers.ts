import { getBorrowers } from './controller-functions/get-borrowers'
import { ethers, network } from 'hardhat';
import * as dotenv from 'dotenv';
dotenv.config();

async function main() {
    let latestBlock = await ethers.provider.getBlockNumber();

    for (let i = 0; i < 100; i++) {
        console.log(await getBorrowers(latestBlock - 5000, latestBlock));
        latestBlock -= 5000;
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/controller/01-controller-scripts/get-borrowers.ts --network zeta_testnet
// npx hardhat run scripts/controller/01-controller-scripts/get-borrowers.ts --network zeta_mainnet