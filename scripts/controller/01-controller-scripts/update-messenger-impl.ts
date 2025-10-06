import { updateMessengerImpl } from './controller-functions/update-messenger-impl';
import { ethers, network } from 'hardhat';
import * as dotenv from 'dotenv';
dotenv.config();

const config = {
    // Set to null to deploy new implementation, or provide the address of an existing implementation
    newMessengerImpl: null
}

async function main() {
    await updateMessengerImpl(config.newMessengerImpl);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/controller/01-controller-scripts/update-messenger-impl.ts --network zeta_testnet
// npx hardhat run scripts/controller/01-controller-scripts/update-messenger-impl.ts --network zeta_mainnet