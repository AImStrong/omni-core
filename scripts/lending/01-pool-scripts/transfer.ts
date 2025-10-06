import { ethers, network } from 'hardhat';
import { transfer } from '../../utils/transfer';
import { encode } from '../../utils/encode';

const config = {
    to: '0x81ff99181d4Bdd14f64dC1a0e1A98EF81688bA0a',
    asset: '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913',
    amount: ethers.utils.parseUnits('0.000001', 6)
}

async function main() {
    await transfer(config.to, config.asset, config.amount);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/lending/01-pool-scripts/transfer.ts --network bsc_testnet
// npx hardhat run scripts/lending/01-pool-scripts/transfer.ts --network base_mainnet
