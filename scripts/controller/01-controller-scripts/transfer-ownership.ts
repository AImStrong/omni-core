import { transferOwnership } from './controller-functions/transfer-ownership';
import { ethers, network } from 'hardhat';
import * as dotenv from 'dotenv';
dotenv.config();

const config = {
    newOwner: '0xA69c42271B9d539877ce83579db308b61F41F892',
    currentOwner: '0x2c0E21F7C0E4bd6B1A82AB66164db747Fc40e54e',
}

async function main() {
    await transferOwnership(config.newOwner, config.currentOwner);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/controller/01-controller-scripts/transfer-ownership.ts --network zeta_testnet
// npx hardhat run scripts/controller/01-controller-scripts/transfer-ownership.ts --network zeta_mainnet