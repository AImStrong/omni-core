import { updateAddressesProviderImpl } from './controller-functions/update-addresses-provider-impl';
import { ethers, network } from 'hardhat';
import * as dotenv from 'dotenv';
dotenv.config();

const config = {
    // Set to null to deploy new implementation, or provide the address of an existing implementation
    newAddressesProviderImpl: null
}

async function main() {
    await updateAddressesProviderImpl(config.newAddressesProviderImpl);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/controller/01-controller-scripts/update-addresses-provider-impl.ts --network zeta_testnet 