import { ethers, network } from 'hardhat';
import * as dotenv from 'dotenv';
dotenv.config();

async function main() {
    const networkName = network.name;
    const oracleAddress = process.env[`${networkName.toUpperCase()}_PRICE_ORACLE`];
    
    if (!oracleAddress) {
        throw new Error(`Oracle address not found for network ${networkName}`);
    }

    const oracle = await ethers.getContractAt("TravaOracle", oracleAddress);
    
    // Get new Pyth oracle address from environment variable
    const newPythAddress = process.env[`${networkName.toUpperCase()}_PYTH_ADDRESS`];
    
    if (!newPythAddress) {
        throw new Error(`New Pyth address not found for network ${networkName}`);
    }

    console.log(`Updating Pyth oracle address to ${newPythAddress}...`);
    const tx = await oracle.updatePythOracle(newPythAddress);
    await tx.wait();
    console.log(`Pyth oracle address updated successfully`);

    const pyth  = await oracle.pyth();
    console.log(`Pyth address: ${pyth}`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 
// npx hardhat run scripts/controller/03-oracle-scripts/03-update-pyth-oracle.ts --network zeta_testnet
