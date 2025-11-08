import { ethers, network } from 'hardhat';
import { encode, transfer } from "../../utils";
import * as dotenv from "dotenv";
dotenv.config();

const config = {
    asset: "0x4200000000000000000000000000000000000006",
    to: "0x239b8ecc620B0DFa2340B7fb10D4feE793EF983c",
    user: "0x239b8ecc620B0DFa2340B7fb10D4feE793EF983c",
}

async function main() {

    const system = await ethers.getContractAt("ISystem", "0x91d18e54DAf4F677cB28167158d6dd21F6aB3921");
    const universal = await ethers.getContractAt("UniversalMessenger", "0x18351419aE86F3DD3128943ec01b873b4f35801D");

    const gasAddress = await system.gasCoinZRC20ByChainId(56);
    console.log(gasAddress);

    const balance = await universal.getUserGasBalance(config.user, gasAddress);
    console.log(balance);
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
