import { ethers, network } from 'hardhat';
import { writeToEnvFile } from '../../utils/helper';
import * as dotenv from 'dotenv';
dotenv.config();

async function deploy(tokenName: string) {

    const networkName = network.name;

    // ========= deploy token =========
    console.log(`========= deploy ${tokenName} token =========`);

    const Token = await ethers.getContractFactory("TempToken");
    const token = await Token.deploy(tokenName, tokenName.toUpperCase(), 18);
    await token.deployed();

    console.log(`${networkName.toUpperCase()}_${tokenName.toUpperCase()}_TOKEN`, token.address);
    writeToEnvFile(`${networkName.toUpperCase()}_${tokenName.toUpperCase()}_TOKEN`, token.address);
    console.log('\n');
}

async function main() {
    await deploy('USDC');
    await deploy('USDT');
    await deploy('BTCB');
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/lending/00-deploy-pool/06-deploy-bep20.ts --network bsc_testnet