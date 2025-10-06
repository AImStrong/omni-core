import { setConnectedMessengersForChains } from './controller-functions/set-connected';
import { ethers, network } from 'hardhat';
import * as dotenv from 'dotenv';
dotenv.config();

const config = {
    chainIds: [96, 56],
    messengerAddrs: ['0xe2dC357BcECFFeb321a8ACc09b6ffcfCbBC335C2', '0x939bF797376B7158Cb5E1af3ca79E34B4aF0826f']
}

async function main() {
    await setConnectedMessengersForChains(config.chainIds, config.messengerAddrs);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/controller/01-controller-scripts/set-connected.ts --network zeta_testnet
// npx hardhat run scripts/controller/01-controller-scripts/set-connected.ts --network zeta_mainnet