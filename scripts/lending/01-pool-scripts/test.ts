import { ethers, network } from 'hardhat';
import { encode } from "../../utils";
import * as dotenv from "dotenv";
dotenv.config();

async function main() {

    const provider = await ethers.getContractAt(
        "contracts/lending-protocol/factory/AddressesProvider.sol:AddressesProvider", 
        process.env[`${network.name.toUpperCase()}_ADDRESSES_PROVIDER_PROXY`]!
    );
    console.log(await provider.getGovernance());
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/lending/01-pool-scripts/test.ts --network bsc_testnet
// npx hardhat run scripts/lending/01-pool-scripts/test.ts --network base_mainnet
// npx hardhat run scripts/lending/01-pool-scripts/test.ts --network zeta_mainnet
