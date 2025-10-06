import { 
    setReserveActive,
    setReserveFrozen,
    setReserveBorrowingEnabled,
    setPoolPause
} from './pool-functions/enable-disable';

import * as dotenv from 'dotenv';
dotenv.config();

const config = {
    asset: '0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f',
}

async function main() {
    // await setReserveActive(config.asset, true);
    // await setReserveFrozen(config.asset, true);
    // await setReserveBorrowingEnabled(config.asset, true, false); // variable = true, stable = false
    await setPoolPause(false);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/lending/01-pool-scripts/enable-disable.ts --network bsc_testnet
// npx hardhat run scripts/lending/01-pool-scripts/enable-disable.ts --network arbitrum_one_mainnet
// npx hardhat run scripts/lending/01-pool-scripts/enable-disable.ts --network base_mainnet
// npx hardhat run scripts/lending/01-pool-scripts/enable-disable.ts --network bsc_mainnet