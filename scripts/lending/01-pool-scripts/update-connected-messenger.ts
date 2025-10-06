import { ethers } from "hardhat";
import { updateConnectedMessengerImpl } from "./pool-functions/update-connected-messenger-impl";
import * as dotenv from 'dotenv';
dotenv.config();

async function main() {
  await updateConnectedMessengerImpl();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 

// if you want to update the connected messenger, you can pass the new address to the function, 
// otherwise it will deploy a new one

// npx hardhat run scripts/lending/01-pool-scripts/update-connected-messenger.ts --network bsc_testnet
// npx hardhat run scripts/lending/01-pool-scripts/update-connected-messenger.ts --network base_mainnet
// npx hardhat run scripts/lending/01-pool-scripts/update-connected-messenger.ts --network arbitrum_one_mainnet