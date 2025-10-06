import { ethers, network } from 'hardhat';
import { encode } from '../../utils/encode';
import { BigNumber } from 'ethers';
import * as dotenv from 'dotenv';
dotenv.config();

async function main() {
    const networkName = network.name;
    const oracleAddress = process.env[`${networkName.toUpperCase()}_PRICE_ORACLE`];
    
    if (!oracleAddress) {
        throw new Error(`Oracle address not found for network ${networkName}`);
    }

    const oracle = await ethers.getContractAt("TravaOracle", oracleAddress);
    
    // Set max price staleness in seconds (e.g., 60 seconds)
    const maxPriceStaleness = BigNumber.from("0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");

    console.log(`Setting max price staleness to ${maxPriceStaleness} seconds...`);
    const data = encode("setMaxPriceStaleness(uint256)", [maxPriceStaleness]);
    console.log(data);
    console.log(`Max price staleness: `, await oracle.maxPriceStaleness());
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 

// npx hardhat run scripts/controller/03-oracle-scripts/02-set-max-price-staleness.ts --network zeta_testnet
// npx hardhat run scripts/controller/03-oracle-scripts/02-set-max-price-staleness.ts --network zeta_mainnet