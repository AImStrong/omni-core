import { transferOwnership, transferGovernance } from './pool-functions/transfer-ownership';
import { ethers, network } from 'hardhat';
import * as dotenv from 'dotenv';
dotenv.config();

const config = {
    newOwner: '0x86A36A5baAa5C60036e758CAa1a4dAd32E6a5af4',
    currentOwner: '0x2c0E21F7C0E4bd6B1A82AB66164db747Fc40e54e',
    newGovernance: '0x81ff99181d4Bdd14f64dC1a0e1A98EF81688bA0a',
}

async function main() {
    // await transferOwnership(config.newOwner, config.currentOwner);
    await transferGovernance(config.newGovernance);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/lending/01-pool-scripts/transfer-ownership.ts --network bsc_testnet
// npx hardhat run scripts/lending/01-pool-scripts/transfer-ownership.ts --network base_mainnet
// npx hardhat run scripts/lending/01-pool-scripts/transfer-ownership.ts --network arbitrum_one_mainnet