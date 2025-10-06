import { setAddress } from './controller-functions/set-address';
import { ethers, network } from 'hardhat';
import * as dotenv from 'dotenv';
dotenv.config();

async function main() {
    let networkName = network.name;

    await setAddress('UniversalMessenger', process.env[`${networkName.toUpperCase()}_UNIVERSAL_MESSENGER_PROXY`]!);
    await setAddress('PriceOracle', process.env[`${networkName.toUpperCase()}_PRICE_ORACLE`]!);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/controller/01-controller-scripts/set-address.ts --network zeta_testnet