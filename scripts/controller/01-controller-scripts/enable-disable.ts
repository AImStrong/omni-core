import { 
    setReserveActive,
    setReserveBorrowingEnabled,
    setReserveFrozen,
    setPoolPause,
    setControllerPause
} from './controller-functions/enable-disable';
import { ethers, network } from 'hardhat';
import * as dotenv from 'dotenv';
dotenv.config();

const config = {
    chainId: 8453,
    asset: '0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf',
}

async function main() {
    // await setReserveActive(config.chainId, config.asset, false);
    // await setReserveBorrowingEnabled(config.chainId, config.asset, true, false); // variable = true, stable = false
    // await setReserveFrozen(config.chainId, config.asset, true);
    // await setPoolPause(config.chainId, true);
    await setControllerPause(false);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/controller/01-controller-scripts/enable-disable.ts --network zeta_testnet
// npx hardhat run scripts/controller/01-controller-scripts/enable-disable.ts --network zeta_mainnet