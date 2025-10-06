import { ethers } from "hardhat";
import { updateAddressProviderImpl } from "./pool-functions/update-address-provider-impl";
import * as dotenv from 'dotenv';
dotenv.config();

async function main() {
  await updateAddressProviderImpl(); 
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 

// if you want to update the address provider, you can pass the new address to the function, 
// otherwise it will deploy a new one

// npx hardhat run scripts/lending/01-pool-scripts/update-address-provider.ts --network bsc_testnet
// npx hardhat run scripts/lending/01-pool-scripts/update-address-provider.ts --network base_mainnet
// npx hardhat run scripts/lending/01-pool-scripts/update-address-provider.ts --network arbitrum_one_mainnet